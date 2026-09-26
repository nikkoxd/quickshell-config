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
        // Hints the spec defines for sound but Quickshell has no property for.
        // Without listing them here `hints` never carries them.
        extraHints: ["sound"]
    }

    // True when the notification's own app has already made a noise for it, so
    // chiming again would double up.
    //
    // `suppress-sound` is the spec's answer, but almost nothing sets it here:
    // an app only bothers when the server advertises the `sound` capability in
    // GetCapabilities, and Quickshell's NotificationServer has no such flag.
    // Telegram and Discord therefore play their own sound and say nothing about
    // it, which is what the user-maintained list is for. It matches against the
    // app name and the desktop-entry hint, case-insensitively, so either
    // "Discord" or "com.ayugram.desktop" identifies a sender.
    function playsItsOwnSound(notification) {
        if (notification.hints && (notification.hints["suppress-sound"]))
            return true;

        const names = Config.notifications.silentApps;
        if (!names || names.length === 0)
            return false;

        const appName = String(notification.appName || "").toLowerCase();
        const entry = String((notification.hints && notification.hints["desktop-entry"]) || notification.desktopEntry || "").toLowerCase();

        for (let i = 0; i < names.length; i++) {
            const name = String(names[i] || "").toLowerCase().trim();
            if (name && (name === appName || name === entry))
                return true;
        }
        return false;
    }

    // The chime lives here rather than in the view that pops up, so a
    // notification arriving over an interactive view is still heard even
    // though nothing is shown for it.
    Connections {
        target: server
        function onNotification(notification) {
            if (root.muted || root.playsItsOwnSound(notification))
                return;

            const soundFile = notification.hints && notification.hints["sound-file"];
            if (soundFile) {
                SoundService.playPath(String(soundFile), Config.notifications.soundVolume);
            } else {
                SoundService.playNotification();
            }
        }
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
