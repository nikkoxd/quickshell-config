pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Core

// Unit table behind the launcher's service manager provider, covering both the
// system and the user manager. Like ProcessService it only refreshes while something
// asks for it (`polling`), and rows are QObjects pooled per unit so the launcher's
// ScriptModel diffs a refresh into property updates instead of a reset.
//
// The table is two listings merged: `list-units --all` for what is loaded (cheap,
// polled), and `list-unit-files` for the enablement state and for units that exist on
// disk but were never loaded. The second makes pid 1 stat every unit file it knows —
// most of a second on the system manager — so it is not polled: it is read when the
// table opens and again after an action that changes it.
//
// Actions go through `systemctl` itself. On the system manager that means polkit, so
// anything privileged pops the island's own prompt (PolkitService) — systemctl asks
// for interactive authorization by default, and a failed or refused one comes back
// as a notification.
Singleton {
    id: root

    // The table as the launcher shows it: filtered and sorted per Config.launcher.
    // Row properties are on UnitRow below.
    property var rows: []

    readonly property string scope: Config.launcher.systemdScope
    readonly property bool servicesOnly: Config.launcher.systemdServicesOnly
    readonly property string sortField: Config.launcher.systemdSort

    onScopeChanged: root.rebuild()
    onServicesOnlyChanged: root.rebuild()
    onSortFieldChanged: root.rebuild()

    // Set by whoever is showing the table; gates the refresh timer.
    property bool polling: false

    // Unit types fetched. Devices, slices and scopes are left out entirely: they
    // can't be meaningfully started, stopped or enabled, and they outnumber the rest.
    readonly property string types: "service,timer,socket,path,mount,automount,target,swap"

    // Last listings, as { system: [...], user: [...] } of systemctl's JSON rows.
    property var units: ({ system: [], user: [] })
    property var files: ({ system: [], user: [] })

    // "scope:unit" -> row.
    property var rowCache: ({})

    component UnitRow: QtObject {
        property string unit
        // "system" or "user": which manager the unit belongs to.
        property string scope
        property string load
        property string active
        property string sub
        property string description
        // `list-unit-files` state (enabled, disabled, static, masked, ...); empty for
        // units with no file of their own, like template instances.
        property string fileState

        // Filled in by inspect() when the row is drilled into. Until then the
        // action list offers what the active state alone suggests.
        property bool canStart: true
        property bool canStop: true
        property bool canReload: false

        // Identity across scopes: the user manager has its own dbus.service,
        // pipewire.socket and so on, so the unit name alone collides.
        property string key

        // Launcher entry fields. `iconType`, `preventClose` and `execute` are filled
        // in by the provider — icon types live in qs.Modules.Launcher.Providers,
        // which a service can't import.
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
        if (root.polling) {
            root.refresh();
            root.refreshFiles();
        }
    }

    function refresh() {
        if (!unitsProc.running)
            unitsProc.running = true;
    }

    function refreshFiles() {
        if (!filesProc.running)
            filesProc.running = true;
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.polling
        onTriggered: root.refresh()
    }

    // Lists both managers in one spawn, each listing behind an "@<scope>" line. A
    // manager that can't be reached prints nothing, which parses as an empty list.
    readonly property string listScript: 'for scope in system user; do\n'
        + '  flag=; [ "$scope" = user ] && flag=--user\n'
        + '  printf "@%s\\n" "$scope"\n'
        + '  systemctl $flag "$1" --all --output=json --no-pager --type="$2" 2>/dev/null\n'
        + '  echo\n'
        + 'done'

    function parseListing(text) {
        const out = { system: [], user: [] };
        let scope = "";
        for (const line of text.split("\n")) {
            if (line.startsWith("@")) {
                scope = line.slice(1);
                continue;
            }
            if (!line.trim() || !(scope in out))
                continue;
            try {
                out[scope] = JSON.parse(line);
            } catch (e) {
                console.warn("SystemdService: unparsable", scope, "listing:", e);
            }
        }
        return out;
    }

    Process {
        id: unitsProc
        command: ["sh", "-c", root.listScript, "sh", "list-units", root.types]
        stdout: StdioCollector {
            onStreamFinished: {
                root.units = root.parseListing(this.text);
                root.rebuild();
            }
        }
    }

    Process {
        id: filesProc
        command: ["sh", "-c", root.listScript, "sh", "list-unit-files", root.types]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = root.parseListing(this.text);
                root.rebuild();
            }
        }
    }

    // Rebuilds `rows` from the last listings. Called off the back of a refresh and
    // whenever the relevant settings change — never from a binding.
    function rebuild() {
        const list = [];
        const seen = ({});
        const scopes = root.scope === "both" ? ["system", "user"] : [root.scope];

        for (const scope of scopes) {
            const fileStates = ({});
            for (const file of root.files[scope] ?? [])
                fileStates[file.unit_file] = file.state;

            const listed = ({});
            for (const unit of root.units[scope] ?? []) {
                listed[unit.unit] = true;
                // A unit something references but nothing provides. Noise here.
                if (unit.load === "not-found" && !fileStates[unit.unit])
                    continue;
                list.push(root.update(seen, scope, unit.unit, unit.load, unit.active,
                                      unit.sub, unit.description, fileStates[unit.unit] ?? ""));
            }

            // Units that exist on disk but aren't loaded: never started, or stopped
            // and garbage collected. Templates can't be started without an instance,
            // and aliases are already listed under their real name.
            for (const unit in fileStates) {
                const state = fileStates[unit];
                if (listed[unit] || state === "alias" || /@\.[a-z]+$/.test(unit))
                    continue;
                const masked = state.startsWith("masked");
                list.push(root.update(seen, scope, unit, masked ? "masked" : "loaded",
                                      "inactive", "dead", "", state));
            }
        }

        root.prune(seen);
        const filtered = root.servicesOnly ? list.filter(row => row.unit.endsWith(".service")) : list;
        root.rows = root.sort(filtered, root.sortField);
    }

    function update(seen, scope, unit, load, active, sub, description, fileState) {
        const key = scope + ":" + unit;
        let row = root.rowCache[key];
        if (!row) {
            row = rowComponent.createObject(root, { key, scope, unit });
            root.rowCache[key] = row;
        }
        seen[key] = true;

        row.load = load;
        row.active = active;
        row.sub = sub;
        row.description = description;
        row.fileState = fileState;
        row.name = root.servicesOnly ? unit.replace(/\.service$/, "") : unit;
        row.icon = root.iconFor(row);

        const parts = [load === "masked" ? "masked" : sub];
        if (fileState && fileState !== "masked")
            parts.push(fileState);
        if (root.scope === "both")
            parts.push(scope);
        row.genericName = parts.join(" · ");
        row.search = (unit + " " + description).toLowerCase();
        return row;
    }

    function prune(seen) {
        for (const key in root.rowCache) {
            if (seen[key])
                continue;
            root.rowCache[key].destroy();
            delete root.rowCache[key];
        }
    }

    Component {
        id: rowComponent
        UnitRow {}
    }

    function iconFor(row) {
        if (row.load === "masked")
            return "prohibit";
        if (row.active === "failed")
            return "warning-circle";
        if (["activating", "deactivating", "reloading"].includes(row.active))
            return "circle-notch";
        if (row.active === "active")
            return row.sub === "running" ? "play-circle" : "check-circle";
        return "circle-dashed";
    }

    // Failed first, then whatever is up, then the rest, so the units worth looking
    // at sit at the top of an empty query.
    function rank(row) {
        if (row.active === "failed")
            return 0;
        if (row.active === "inactive")
            return 2;
        return 1;
    }

    // `field` is one of state / name, as stored in Config.launcher.
    function sort(list, field) {
        const sorted = list.slice();
        if (field === "name")
            sorted.sort((a, b) => a.unit.localeCompare(b.unit) || a.scope.localeCompare(b.scope));
        else
            sorted.sort((a, b) => root.rank(a) - root.rank(b)
                               || a.unit.localeCompare(b.unit)
                               || a.scope.localeCompare(b.scope));
        return sorted;
    }

    function isActive(row) {
        return ["active", "activating", "reloading"].includes(row.active);
    }

    function scopeArgs(row) {
        return row.scope === "user" ? ["systemctl", "--user"] : ["systemctl"];
    }

    // Asks the manager what the unit supports, so the action list stops offering a
    // reload to a unit that has no ExecReload.
    function inspect(row) {
        row.canReload = false;
        const proc = inspectComponent.createObject(root, { row });
        proc.command = root.scopeArgs(row).concat(["show", "-p", "CanStart,CanStop,CanReload", "--", row.unit]);
        proc.running = true;
    }

    Component {
        id: inspectComponent
        Process {
            id: inspectProc
            property UnitRow row
            stdout: StdioCollector {
                onStreamFinished: {
                    const row = inspectProc.row;
                    if (row) {
                        for (const line of this.text.split("\n")) {
                            const [name, value] = line.split("=");
                            if (name === "CanStart")
                                row.canStart = value === "yes";
                            else if (name === "CanStop")
                                row.canStop = value === "yes";
                            else if (name === "CanReload")
                                row.canReload = value === "yes";
                        }
                    }
                    inspectProc.destroy();
                }
            }
        }
    }

    // Verbs that change the unit's file state rather than (only) its runtime state,
    // so the slow listing has to be read again after them.
    readonly property var fileVerbs: ["enable", "disable", "mask", "unmask"]

    // Runs `systemctl <verb> <unit>` on the row's manager. systemctl's own output is
    // folded into stdout behind its exit code, so one stream says how it went.
    function run(row, verb) {
        const proc = actionComponent.createObject(root, { verb, unit: row.unit });
        proc.command = ["sh", "-c", 'out=$("$@" 2>&1); code=$?; printf "%s\\n%s" "$code" "$out"', "sh"]
            .concat(root.scopeArgs(row), [verb, "--", row.unit]);
        proc.running = true;
    }

    Component {
        id: actionComponent
        Process {
            id: actionProc
            property string verb
            property string unit
            stdout: StdioCollector {
                onStreamFinished: {
                    const newline = this.text.indexOf("\n");
                    const code = parseInt(newline === -1 ? this.text : this.text.slice(0, newline));
                    const output = newline === -1 ? "" : this.text.slice(newline + 1).trim();
                    if (code !== 0)
                        NotificationService.notify("systemctl " + actionProc.verb + " " + actionProc.unit + " failed",
                                                   output || "exit code " + code);

                    // The table is stale the moment the action lands; read it again
                    // rather than waiting out the poll interval.
                    root.refresh();
                    if (root.fileVerbs.includes(actionProc.verb))
                        root.refreshFiles();
                    actionProc.destroy();
                }
            }
        }
    }

    function copyName(unit) {
        Quickshell.execDetached(["wl-copy", "--", unit]);
    }
}
