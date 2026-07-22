import Quickshell
import qs.Core

LauncherProvider {
    id: root
    providerId: "default"
    headerIcon: "search"
    placeholder: "Search..."

    property var customEntries: [
        {
            name: "Select Theme",
            genericName: "Quickshell",
            icon: "color_lens",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "themes";
            }
        },
        {
            name: "Passwords",
            genericName: "KeePassXC",
            icon: "key",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "passwords";
            }
        },
        {
            name: "Emoji",
            genericName: "Picker",
            icon: "mood",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "emoji";
            }
        },
        {
            name: "Dashboard",
            genericName: "Quickshell",
            icon: "dashboard",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("dashboard");
            }
        },
        {
            name: "Wallpapers",
            genericName: "Quickshell",
            icon: "wallpaper",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("wallpapers");
            }
        },
        {
            name: "Audio Mixer",
            genericName: "Quickshell",
            icon: "graphic_eq",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("mixer");
            }
        },
        {
            name: "Bluetooth",
            genericName: "Quickshell",
            icon: "bluetooth",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("bluetooth");
            }
        },
        {
            name: "Notifications",
            genericName: "Quickshell",
            icon: "notification",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("notifications");
            }
        },
        {
            name: "Bar Settings",
            genericName: "Quickshell",
            icon: "settings",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("settings");
            }
        },
        {
            name: "Next Track",
            genericName: "MPRIS",
            icon: "skip_next",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.mpris.next();
            }
        },
        {
            name: "Power Off",
            genericName: "Power",
            icon: "power_settings_new",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["systemctl", "poweroff"])
            }
        },
        {
            name: "Reboot",
            genericName: "Power",
            icon: "restart_alt",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["systemctl", "reboot"])
            }
        },
        {
            name: "Suspend",
            genericName: "Power",
            icon: "pause",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["systemctl", "suspend"])
            }
        },
        {
            name: "Lock",
            genericName: "Power",
            icon: "lock",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["loginctl", "lock-session"])
            }
        },
        {
            name: "Previous Track",
            genericName: "MPRIS",
            icon: "skip_previous",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.mpris.previous();
            }
        },
        {
            name: "Play/Pause Track",
            genericName: "MPRIS",
            icon: "play_arrow",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.mpris.togglePlaying();
            }
        },
    ]

    function entries(query) {
        const q = query;

        if (!q && !Config.launcher.showResultsWithEmptyQuery)
            return [];

        const all = [...DesktopEntries.applications.values, ...root.customEntries];
        const results = root.svc.fuzzyFilter(q, all, ["name", "genericName"]);

        const calcResult = root.svc.evalMath(q);
        if (calcResult !== null) {
            const calcEntry = {
                name: q + " = " + calcResult,
                genericName: "Calculator",
                execute: function () {
                    Quickshell.execDetached(["wl-copy", calcResult.toString()]);
                }
            };
            results.unshift(calcEntry);
        }

        return results;
    }
}
