import QtQuick
import qs.Core
import qs.Services

LauncherProvider {
    id: root
    providerId: "systemd"
    headerIcon: "gear-six"
    placeholder: root.selected
        ? (root.selected.description || root.selected.unit)
        : root.servicesOnly ? "Search services..." : "Search units..."

    // The row drilled into, as produced by SystemdService.rows.
    property var selected: null

    readonly property string scope: Config.launcher.systemdScope
    readonly property bool servicesOnly: Config.launcher.systemdServicesOnly

    // The table only polls while this provider is the one on screen.
    readonly property bool active: root.svc.provider === root.providerId
    onActiveChanged: {
        SystemdService.polling = root.active;
        if (!root.active)
            root.selected = null;
    }
    Component.onDestruction: SystemdService.polling = false

    function goBack() {
        if (root.selected) {
            root.backToTable();
            return true;
        }
        root.svc.provider = "default";
        return true;
    }

    function drillInto(row) {
        SystemdService.inspect(row);
        root.selected = row;
        root.svc.clearQueryRequested();
    }

    // The action list returns here once it has acted, so several units can be dealt
    // with without reopening the launcher.
    function backToTable() {
        root.selected = null;
        root.svc.clearQueryRequested();
    }

    // Same arrangement as the process manager: the launcher-side fields are stamped
    // on off the service's signal, never from entries() (which runs inside the
    // model's binding), and every refresh, so `execute` never points at a provider
    // from a previous open.
    function stamp() {
        for (const row of SystemdService.rows) {
            row.iconType = LauncherProvider.IconType.Material;
            row.preventClose = true;
            row.execute = () => root.drillInto(row);
        }
    }

    property Connections serviceConnections: Connections {
        target: SystemdService
        function onRowsChanged() {
            root.stamp();
        }
    }

    Component.onCompleted: root.stamp()

    // What each verb does, shown beside it in the action list. Kept short: the row
    // has no room to wrap. Start, stop and restart say it themselves.
    readonly property var verbDescriptions: ({
        reload: "re-read config without stopping",
        "reset-failed": "clear the failed state",
        enable: "start automatically at {when}",
        disable: "stop starting at {when}",
        mask: "block it from starting at all",
        unmask: "allow it to start again"
    })

    function action(row, name, verb, icon) {
        return {
            name: name,
            // User units come up with the session, system units with the machine.
            genericName: (root.verbDescriptions[verb] ?? "")
                .replace("{when}", row.scope === "user" ? "login" : "boot"),
            icon: icon,
            iconType: LauncherProvider.IconType.Material,
            usageKey: "",
            preventClose: true,
            execute: function () {
                SystemdService.run(row, verb);
                root.backToTable();
            }
        };
    }

    // Offers what the unit's state allows. canStart/canStop/canReload come in from
    // SystemdService.inspect() a moment after the list opens; reading them here makes
    // the list follow along.
    function actions(row) {
        const list = [];
        const masked = row.load === "masked" || row.fileState.startsWith("masked");

        if (SystemdService.isActive(row)) {
            if (row.canStop)
                list.push(root.action(row, "Stop", "stop", "stop"));
            list.push(root.action(row, "Restart", "restart", "arrow-clockwise"));
            if (row.canReload)
                list.push(root.action(row, "Reload", "reload", "arrows-clockwise"));
        } else if (!masked && row.canStart) {
            list.push(root.action(row, "Start", "start", "play"));
        }

        if (row.active === "failed")
            list.push(root.action(row, "Reset failed state", "reset-failed", "eraser"));

        if (row.fileState === "enabled")
            list.push(root.action(row, "Disable", "disable", "toggle-left"));
        else if (row.fileState === "disabled")
            list.push(root.action(row, "Enable", "enable", "toggle-right"));

        // Runtime masks live under /run and are gone on reboot; `unmask` only
        // touches the persistent one, so it's offered for that alone.
        if (row.fileState === "masked")
            list.push(root.action(row, "Unmask", "unmask", "lock-open"));
        else if (!masked && row.fileState)
            list.push(root.action(row, "Mask", "mask", "prohibit"));

        list.push({
            name: "Copy unit name",
            genericName: row.unit,
            icon: "clipboard",
            iconType: LauncherProvider.IconType.Material,
            usageKey: "",
            execute: function () {
                SystemdService.copyName(row.unit);
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

    readonly property var nextScope: ({ both: "user", user: "system", system: "both" })

    readonly property var scopeToggle: ({
        name: root.scope === "both" ? "Show only user units"
            : root.scope === "user" ? "Show only system units"
            : "Show user and system units",
        genericName: root.scope === "both" ? "user + system" : root.scope,
        icon: root.scope === "both" ? "users-three" : root.scope === "user" ? "user" : "hard-drives",
        iconType: LauncherProvider.IconType.Material,
        usageKey: "",
        preventClose: true,
        execute: function () {
            Config.launcher.systemdScope = root.nextScope[root.scope] ?? "both";
        }
    })

    readonly property var typeToggle: ({
        name: root.servicesOnly ? "Show all unit types" : "Show only services",
        genericName: root.servicesOnly ? "services" : "timers, sockets, mounts, ...",
        icon: "funnel",
        iconType: LauncherProvider.IconType.Material,
        usageKey: "",
        preventClose: true,
        execute: function () {
            Config.launcher.systemdServicesOnly = !Config.launcher.systemdServicesOnly;
        }
    })

    function entries(query) {
        if (root.selected) {
            const list = root.actions(root.selected);
            return query ? root.svc.fuzzyFilter(query, list) : list;
        }

        // Substring, as in the process manager: hundreds of units make fuzzy
        // matching far too loose.
        const matched = root.svc.substringFilter(query, SystemdService.rows, 100);
        return query ? matched : [root.scopeToggle, root.typeToggle].concat(matched);
    }
}
