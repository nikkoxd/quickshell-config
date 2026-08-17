import Quickshell
import qs.Core
import qs.Services

LauncherProvider {
    id: root
    providerId: "default"
    headerIcon: "magnifying-glass"
    placeholder: "Search..."

    property var customEntries: [
        {
            name: "Switch to Big Picture",
            genericName: "big picture",
            icon: "desktop",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["sh", "-c", "steamos-session-select gamescope"])
            }
        },
        {
            name: "Settings",
            genericName: "settings",
            icon: "gear-six",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.settingsRequested();
            }
        },
        {
            name: "Select Theme",
            genericName: "colorscheme",
            icon: "palette",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "themes";
            }
        },
        {
            name: "Passwords",
            genericName: "keepassxc",
            icon: "password",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "passwords";
            }
        },
        {
            name: "Emoji",
            genericName: "emoji",
            icon: "smiley",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "emoji";
            }
        },
        {
            name: "Clipboard history",
            genericName: "clipboard",
            icon: "clipboard",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "clipboard";
            }
        },
        {
            name: "Wipe clipboard",
            genericName: "wipe clipboard",
            icon: "trash-simple",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                CliphistService.wipe();
            }
        },
        {
            name: "Recording options",
            genericName: "recording options",
            icon: "gear-six",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("recorder");
            }
        },
        {
            name: "Record video (toggle)",
            genericName: "toggle video",
            icon: "video-camera",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                RecordingService.toggleRecording();
            }
        },
        {
            name: "Toggle replay recording",
            genericName: "toggle replay",
            icon: "arrows-clockwise",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                RecordingService.toggleReplay();
            }
        },
        {
            name: "Save replay",
            genericName: "save replay",
            icon: "floppy-disk",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                RecordingService.saveReplay();
            }
        },
        {
            name: "Dashboard",
            genericName: "dashboard",
            icon: "cards-three",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("dashboard");
            }
        },
        {
            name: "Wallpapers",
            genericName: "wallpapers",
            icon: "image",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("wallpaperSelector");
            }
        },
        {
            name: "Audio Mixer",
            genericName: "mixer",
            icon: "faders",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("mixer");
            }
        },
        {
            name: "Bluetooth",
            genericName: "bluetooth",
            icon: "bluetooth",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("bluetooth");
            }
        },
        {
            name: "Notifications",
            genericName: "notifications",
            icon: "bell",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("notifications");
            }
        },
        {
            name: "Next Track",
            genericName: "mpris next",
            icon: "skip-forward",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.mpris.next();
            }
        },
        {
            name: "Power Off",
            genericName: "poweroff",
            icon: "power",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["systemctl", "poweroff"])
            }
        },
        {
            name: "Reboot",
            genericName: "reboot",
            icon: "arrows-clockwise",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["systemctl", "reboot"])
            }
        },
        {
            name: "Suspend",
            genericName: "suspend",
            icon: "pause",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["systemctl", "suspend"])
            }
        },
        {
            name: "Lock",
            genericName: "lock",
            icon: "lock",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["loginctl", "lock-session"])
            }
        },
        {
            name: "Previous Track",
            genericName: "mpris previous",
            icon: "skip-back",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.mpris.previous();
            }
        },
        {
            name: "Play/Pause Track",
            genericName: "mpris playpause",
            icon: "play",
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

        // An empty prefix would match every query, so it disables the prefix instead.
        const customPrefix = Config.launcher.useCustomEntriesPrefix ? Config.launcher.customEntriesPrefix : "";
        const commandPrefix = Config.launcher.commandPrefix;

        if (customPrefix && q.startsWith(customPrefix))
            return root.svc.fuzzyFilter(q.slice(customPrefix.length).trim(), root.customEntries, ["name", "genericName"]);

        if (commandPrefix && q.startsWith(commandPrefix)) {
            const cmd = q.slice(commandPrefix.length).trim();
            if (!cmd) return [];

            return [{
                name: cmd,
                genericName: "Run command",
                icon: "terminal",
                iconType: LauncherProvider.IconType.Material,
                execute: function() { Quickshell.execDetached(["sh", "-c", cmd]) }
            }];
        }

        // Without a prefix to hide behind, custom entries compete with apps directly.
        const pool = customPrefix
            ? DesktopEntries.applications.values
            : Array.from(DesktopEntries.applications.values).concat(root.customEntries);

        const results = root.svc.fuzzyFilter(q, pool, ["name", "genericName"]);

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
