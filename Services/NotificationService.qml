pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.Core

Singleton {
    id: root

    // Do not disturb. Mirrored into Config so it survives a reload; kept as a
    // plain property rather than a binding because every view toggles it by
    // assignment, which would break a binding on the first click.
    property bool muted: false

    Component.onCompleted: root.muted = Config.notifications.doNotDisturb

    onMutedChanged: {
        if (Config.notifications.doNotDisturb !== root.muted) {
            Config.notifications.doNotDisturb = root.muted;
        }
    }

    Connections {
        target: Config.notifications
        function onDoNotDisturbChanged() {
            root.muted = Config.notifications.doNotDisturb;
        }
    }

    property NotificationServer server: NotificationServer {
        id: server
        actionsSupported: true
        keepOnReload: true
    }

    // All tracked notifications, oldest first.
    readonly property var notifications: server.trackedNotifications.values

    // Notifications bucketed per application, as
    // [{ appName, notifications: [newest, ..., oldest] }, ...],
    // groups ordered oldest activity first (matching `notifications`).
    readonly property var groups: buildGroups(notifications)

    function buildGroups(notifs) {
        const buckets = {};
        const lastSeen = {};
        const keys = [];

        for (let i = 0; i < notifs.length; i++) {
            const notif = notifs[i];
            const key = notif.appName || notif.desktopEntry || "";
            if (buckets[key] === undefined) {
                buckets[key] = [];
                keys.push(key);
            }
            buckets[key].unshift(notif);
            lastSeen[key] = i;
        }

        keys.sort((a, b) => lastSeen[a] - lastSeen[b]);
        return keys.map(key => ({
                    appName: key,
                    notifications: buckets[key]
                }));
    }

    function dismissGroup(appName) {
        const group = groups.find(g => g.appName === appName);
        if (!group)
            return;
        // Copy first: dismissing mutates the tracked model the group came from.
        const notifs = group.notifications.slice();
        for (let i = 0; i < notifs.length; i++)
            notifs[i].dismiss();
    }

    function notify(summary, body) {
        notifyProc.command = ["notify-send", "--app-name=Quickshell", summary, body];
        notifyProc.running = true;
    }

    Process {
        id: notifyProc
    }
}
