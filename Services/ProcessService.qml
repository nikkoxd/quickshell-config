pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.Core

// Process table behind the launcher's process manager provider. `ps` is re-run on a
// timer, but only while something asks for it (`polling`), so the shell isn't
// spawning a process every couple of seconds for a view nobody has open.
//
// Rows are QObjects pooled by pid rather than plain JS objects rebuilt each tick.
// ScriptModel can only diff values it can compare, and two structurally identical JS
// objects never compare equal — so a fresh array every two seconds reset the whole
// model, dropping the launcher's selection back to the top. Reusing one object per
// process keeps the diff down to the moves a re-sort actually caused, and the usage
// figures reach the delegates as ordinary property updates.
//
// Filtering, grouping and sorting all happen here rather than in the provider, for
// the same reason: the provider's entries() runs inside the model's binding, and a
// binding that writes to the rows it reads is a binding loop.
Singleton {
    id: root

    // The table as the launcher shows it: filtered, grouped and sorted per
    // Config.launcher. Row properties are on ProcessRow below.
    property var rows: []

    // Every process `ps` reported, in its order. `rows` is derived from this.
    property var processes: []

    readonly property bool grouped: Config.launcher.groupProcesses
    readonly property bool showSystem: Config.launcher.showSystemProcesses
    readonly property string sortField: Config.launcher.processSort

    onGroupedChanged: root.rebuild()
    onShowSystemChanged: root.rebuild()
    onSortFieldChanged: root.rebuild()

    // Set by whoever is showing the table; gates the refresh timer.
    property bool polling: false

    readonly property string user: Quickshell.env("USER") ?? ""

    // pid -> row, and command name -> grouped row. Both are pools: entries are
    // updated in place while the process lives and destroyed once it is gone.
    property var rowCache: ({})
    property var groupCache: ({})

    // Signals offered by the picker, by number.
    readonly property var signals_: [
        { name: "SIGHUP", number: 1, description: "hangup, often reload" },
        { name: "SIGINT", number: 2, description: "interrupt" },
        { name: "SIGQUIT", number: 3, description: "quit with core dump" },
        { name: "SIGKILL", number: 9, description: "kill, cannot be caught" },
        { name: "SIGUSR1", number: 10, description: "user defined 1" },
        { name: "SIGUSR2", number: 12, description: "user defined 2" },
        { name: "SIGTERM", number: 15, description: "terminate" },
        { name: "SIGCONT", number: 18, description: "resume" },
        { name: "SIGSTOP", number: 19, description: "suspend" }
    ]

    component ProcessRow: QtObject {
        property int pid
        // Every pid the row stands for: one for a plain row, the whole group for a
        // grouped one, so a signal reaches all of them.
        property var pids: []
        property string user
        property real cpu
        property int rss
        property string comm
        property string cmdline

        // Launcher entry fields. `icon`, `iconType`, `usageKey`, `preventClose` and
        // `execute` are filled in by the provider — icon types live in
        // qs.Modules.Launcher.Providers, which a service can't import.
        property string name
        property string genericName
        property string search
        property string icon
        property var iconType
        property string usageKey: ""
        property bool preventClose: true
        property var execute
    }

    onPollingChanged: {
        if (root.polling)
            root.refresh();
    }

    function refresh() {
        // ps runs are cheap but not instant; skipping a tick is better than
        // stacking processes when the machine is loaded.
        if (!psProc.running)
            psProc.running = true;
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.polling
        onTriggered: root.refresh()
    }

    Process {
        id: psProc
        command: ["ps", "-eo", "pid=,user=,pcpu=,rss=,comm=,args="]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const seen = ({});

                for (const line of this.text.split("\n")) {
                    // pid user cpu rss comm args — comm never contains a space for
                    // anything we list, so the rest of the line is the command line.
                    const match = /^\s*(\d+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(.*)$/.exec(line);
                    if (!match)
                        continue;

                    const cmdline = match[6];
                    // Kernel threads have a bracketed, argv-less command line. They
                    // can't be usefully signalled from here, so they never show up.
                    if (cmdline.startsWith("[") && cmdline.endsWith("]"))
                        continue;

                    const pid = parseInt(match[1]);
                    const row = root.rowFor(root.rowCache, pid);
                    row.pid = pid;
                    row.pids = [pid];
                    row.user = match[2];
                    row.cpu = parseFloat(match[3]);
                    row.rss = parseInt(match[4]);
                    row.comm = root.name(match[5], cmdline);
                    row.cmdline = cmdline;
                    row.name = row.comm;
                    row.genericName = "pid " + pid + " · " + row.cpu.toFixed(1) + "%"
                                    + " · " + root.formatMemory(row.rss);
                    row.search = (row.comm + " " + pid).toLowerCase();

                    seen[pid] = true;
                    rows.push(row);
                }

                root.prune(root.rowCache, seen);
                root.processes = rows;
                root.rebuild();
            }
        }
    }

    // Rebuilds `rows` from the last `ps` output. Called off the back of a refresh and
    // whenever the relevant settings change — never from a binding.
    function rebuild() {
        let list = root.processes;
        if (!root.showSystem)
            list = list.filter(process => process.user === root.user);
        if (root.grouped)
            list = root.group(list);
        root.rows = root.sort(list, root.sortField);
    }

    // Pooled row for `key`, created on first sight.
    function rowFor(cache, key) {
        let row = cache[key];
        if (!row) {
            row = rowComponent.createObject(root);
            cache[key] = row;
        }
        return row;
    }

    function prune(cache, seen) {
        for (const key in cache) {
            if (seen[key])
                continue;
            cache[key].destroy();
            delete cache[key];
        }
    }

    Component {
        id: rowComponent
        ProcessRow {}
    }

    // The kernel truncates comm at 15 characters, so "gpu-screen-recorder" arrives as
    // "gpu-screen-reco". The executable's basename is the same name untruncated, so
    // prefer it whenever it merely extends comm.
    function name(comm, cmdline) {
        const argv0 = cmdline.split(" ")[0];
        const base = argv0.slice(argv0.lastIndexOf("/") + 1);
        return base.length > comm.length && base.startsWith(comm) ? base : comm;
    }

    // Collapses the table into one row per command name, summing usage. Grouped rows
    // are pooled by name for the same reason plain ones are pooled by pid.
    function group(list) {
        const out = [];
        const seen = ({});

        for (const process of list) {
            let row = root.rowFor(root.groupCache, process.comm);
            if (!seen[process.comm]) {
                seen[process.comm] = true;
                row.comm = process.comm;
                row.name = process.comm;
                row.user = process.user;
                row.pid = process.pid;
                row.pids = [];
                row.cpu = 0;
                row.rss = 0;
                row.cmdline = process.cmdline;
                out.push(row);
            }

            row.pids = row.pids.concat(process.pids);
            row.cpu += process.cpu;
            row.rss += process.rss;
            // The lowest pid is usually the parent, and its command line the one
            // worth showing for the whole group.
            if (process.pid < row.pid) {
                row.pid = process.pid;
                row.cmdline = process.cmdline;
            }
        }

        for (const row of out) {
            const count = row.pids.length;
            row.genericName = (count > 1 ? count + " procs" : "pid " + row.pid)
                            + " · " + row.cpu.toFixed(1) + "%"
                            + " · " + root.formatMemory(row.rss);
            row.search = (row.comm + " " + row.pid).toLowerCase();
        }

        root.prune(root.groupCache, seen);
        return out;
    }

    // `field` is one of cpu / memory / name / pid, as stored in Config.launcher.
    function sort(list, field) {
        const sorted = list.slice();
        if (field === "name")
            sorted.sort((a, b) => a.comm.localeCompare(b.comm) || a.pid - b.pid);
        else if (field === "pid")
            sorted.sort((a, b) => a.pid - b.pid);
        else if (field === "memory")
            sorted.sort((a, b) => b.rss - a.rss || a.pid - b.pid);
        else
            sorted.sort((a, b) => b.cpu - a.cpu || b.rss - a.rss || a.pid - b.pid);
        return sorted;
    }

    function formatMemory(rss) {
        if (rss >= 1024 * 1024)
            return (rss / (1024 * 1024)).toFixed(1) + " GB";
        if (rss >= 1024)
            return Math.round(rss / 1024) + " MB";
        return rss + " KB";
    }

    // `pids` may be a single pid or a list of them, so a grouped row signals every
    // member in one call.
    function sendSignal(pids, signalName) {
        const list = (Array.isArray(pids) ? pids : [pids]).filter(pid => pid > 0);
        if (list.length === 0)
            return;
        Quickshell.execDetached(["kill", "-" + signalName].concat(list.map(pid => String(pid))));
        // The table is stale the moment a signal lands; ask for a fresh one rather
        // than waiting out the poll interval.
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: root.refresh()
    }

    function copyPid(pid) {
        Quickshell.execDetached(["sh", "-c", "printf %s " + pid + " | wl-copy"]);
    }

    // Focuses the window belonging to `pids`, through the toplevel itself rather than
    // a `focuswindow pid:` dispatch — Hyprland's dispatchers are lua now, so the old
    // string form is a parse error on the other end and silently does nothing.
    // A grouped row focuses whichever of its members has a window; with several, the
    // one after the active one, so repeating the action cycles them.
    function focusWindow(pids) {
        const windows = root.windowsFor(pids);
        if (windows.length === 0)
            return;

        let next = 0;
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].wayland?.activated) {
                next = (i + 1) % windows.length;
                break;
            }
        }
        // The activation lives on the wayland toplevel; HyprlandToplevel itself has
        // no activate().
        windows[next].wayland?.activate();
    }

    // Hyprland toplevels belonging to `pids`. The pid lives in the toplevel's last
    // `clients` payload, which is only filled after a refresh — hence refreshWindows()
    // before anything reads this.
    function windowsFor(pids) {
        const list = Array.isArray(pids) ? pids : [pids];
        const windows = [];
        for (const toplevel of Hyprland.toplevels.values)
            if (list.indexOf(toplevel.lastIpcObject?.pid) !== -1)
                windows.push(toplevel);
        return windows;
    }

    // Whether the focus entry would do anything at all.
    function hasWindow(pids) {
        return root.windowsFor(pids).length > 0;
    }

    function refreshWindows() {
        Hyprland.refreshToplevels();
    }
}
