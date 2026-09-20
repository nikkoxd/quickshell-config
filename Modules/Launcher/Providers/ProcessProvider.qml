import QtQuick
import qs.Core
import qs.Services

LauncherProvider {
    id: root
    providerId: "processes"
    headerIcon: "list-magnifying-glass"
    placeholder: root.selected
        ? root.selected.cmdline
        : root.showSystem ? "Search all processes..." : "Search my processes..."

    // The row drilled into, as produced by rows(): carries `pids`, so a grouped
    // row signals every member.
    property var selected: null
    property bool signalPicker: false

    readonly property bool showSystem: Config.launcher.showSystemProcesses
    readonly property bool grouped: Config.launcher.groupProcesses

    // The table only polls while this provider is the one on screen.
    readonly property bool active: root.svc.provider === root.providerId
    onActiveChanged: {
        ProcessService.polling = root.active;
        if (root.active) {
            ProcessService.refreshWindows();
        } else {
            root.selected = null;
            root.signalPicker = false;
        }
    }
    Component.onDestruction: ProcessService.polling = false

    function goBack() {
        if (root.signalPicker) {
            root.signalPicker = false;
            root.svc.clearQueryRequested();
            return true;
        }
        if (root.selected) {
            root.selected = null;
            root.svc.clearQueryRequested();
            return true;
        }
        root.svc.provider = "default";
        return true;
    }

    function drillInto(row) {
        ProcessService.refreshWindows();
        root.selected = row;
        root.svc.clearQueryRequested();
    }

    // Both levels below the table return here once they've acted, so several
    // processes can be dealt with without reopening the launcher.
    function backToTable() {
        root.signalPicker = false;
        root.selected = null;
        root.svc.clearQueryRequested();
    }

    function signalAndReturn(row, signalName) {
        ProcessService.sendSignal(row.pids, signalName);
        root.backToTable();
    }

    // ProcessService hands over the table ready to show — filtered, grouped and
    // sorted. The launcher-side fields are stamped on here, off the service's signal
    // rather than from entries(): entries() runs inside the model's binding, and
    // writing to the rows that binding reads is a binding loop.
    //
    // Re-stamping every refresh also keeps `execute` pointing at *this* provider. The
    // rows outlive the launcher view, so a closure kept from a previous open would
    // call into a destroyed object.
    //
    // `usageKey` stays blank throughout: frecency ranking would fight the configured
    // sort order, and a pid is not an identity worth remembering anyway.
    function stamp() {
        for (const row of ProcessService.rows) {
            row.icon = "cpu";
            row.iconType = LauncherProvider.IconType.Material;
            row.preventClose = true;
            row.execute = () => root.drillInto(row);
        }
    }

    property Connections serviceConnections: Connections {
        target: ProcessService
        function onRowsChanged() {
            root.stamp();
        }
    }

    Component.onCompleted: root.stamp()

    function actions(row) {
        const list = [
            {
                name: "Terminate",
                genericName: "SIGTERM",
                icon: "x-circle",
                iconType: LauncherProvider.IconType.Material,
                usageKey: "",
                preventClose: true,
                execute: function () {
                    root.signalAndReturn(row, "TERM");
                }
            },
            {
                name: "Kill",
                genericName: "SIGKILL",
                icon: "skull",
                iconType: LauncherProvider.IconType.Material,
                usageKey: "",
                preventClose: true,
                execute: function () {
                    root.signalAndReturn(row, "KILL");
                }
            },
            {
                name: "Send signal",
                icon: "broadcast",
                iconType: LauncherProvider.IconType.Material,
                usageKey: "",
                preventClose: true,
                execute: function () {
                    root.signalPicker = true;
                    root.svc.clearQueryRequested();
                }
            },
            {
                name: "Copy PID",
                genericName: String(row.pid),
                icon: "clipboard",
                iconType: LauncherProvider.IconType.Material,
                usageKey: "",
                execute: function () {
                    ProcessService.copyPid(row.pid);
                }
            }
        ];

        if (ProcessService.hasWindow(row.pids))
            list.push({
                name: "Focus window",
                genericName: row.name,
                icon: "selection",
                iconType: LauncherProvider.IconType.Material,
                usageKey: "",
                execute: function () {
                    ProcessService.focusWindow(row.pids);
                }
            });

        list.push({
            name: "Back",
            icon: "arrow-left",
            iconType: LauncherProvider.IconType.Material,
            usageKey: "",
            preventClose: true,
            execute: function () {
                root.backToTable();
            }
        });

        return list;
    }

    function signalEntries(row) {
        const list = ProcessService.signals_.map(signal => ({
            name: signal.name,
            genericName: signal.number + " · " + signal.description,
            icon: "broadcast",
            iconType: LauncherProvider.IconType.Material,
            usageKey: "",
            preventClose: true,
            execute: function () {
                root.signalAndReturn(row, String(signal.number));
            }
        }));

        list.push({
            name: "Back",
            icon: "arrow-left",
            iconType: LauncherProvider.IconType.Material,
            usageKey: "",
            preventClose: true,
            execute: function () {
                root.signalPicker = false;
                root.svc.clearQueryRequested();
            }
        });

        return list;
    }

    readonly property var systemToggle: ({
        name: root.showSystem ? "Show only my processes" : "Show system processes",
        genericName: root.showSystem ? "all users" : ProcessService.user,
        icon: root.showSystem ? "user" : "users-three",
        iconType: LauncherProvider.IconType.Material,
        usageKey: "",
        preventClose: true,
        execute: function () {
            Config.launcher.showSystemProcesses = !Config.launcher.showSystemProcesses;
        }
    })

    function entries(query) {
        if (root.selected) {
            const list = root.signalPicker ? root.signalEntries(root.selected)
                                           : root.actions(root.selected);
            return query ? root.svc.fuzzyFilter(query, list) : list;
        }

        // Substring rather than fuzzy: a process table is long enough that fuzzy
        // matching turns "ssh" into half the list.
        const matched = root.svc.substringFilter(query, ProcessService.rows, 100);
        return query ? matched : [root.systemToggle].concat(matched);
    }
}
