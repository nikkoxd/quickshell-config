import Quickshell
import qs.Core
import qs.Services

LauncherProvider {
    id: root
    providerId: "default"
    headerIcon: "magnifying-glass"
    placeholder: "Search..."

    property var customEntries: [
        // {
        //     name: "Switch to Big Picture",
        //     genericName: "Steam",
        //     icon: "desktop",
        //     iconType: LauncherProvider.IconType.Material,
        //     execute: function() {
        //         Quickshell.execDetached(["sh", "c", "steamos-session-select gamescope"])
        //     }
        // },
        {
            name: "Settings",
            genericName: "Quickshell",
            icon: "gear-six",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.settingsRequested();
            }
        },
        {
            name: "Select Theme",
            genericName: "Quickshell",
            icon: "palette",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "themes";
            }
        },
        {
            name: "Passwords",
            genericName: "KeePassXC",
            icon: "password",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "passwords";
            }
        },
        {
            name: "Emoji",
            genericName: "Picker",
            icon: "smiley",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "emoji";
            }
        },
        {
            name: "Clipboard history",
            genericName: "Clipboard",
            icon: "clipboard",
            iconType: LauncherProvider.IconType.Material,
            preventClose: true,
            execute: function() {
                root.svc.provider = "clipboard";
            }
        },
        /* { */
        /*     name: "Wipe clipboard", */
        /*     genericName: "Clipboard", */
        /*     icon: "content_paste_off", */
        /*     iconType: LauncherProvider.IconType.Material, */
        /*     execute: function() { */
        /*         CliphistService.wipe(); */
        /*     } */
        /* }, */
        {
            name: "Recording options",
            genericName: "Recording",
            icon: "gear-six",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("recorder");
            }
        },
        {
            name: "Record video (toggle)",
            genericName: "Recording",
            icon: "video-camera",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                RecordingService.toggleRecording();
            }
        },
        {
            name: "Toggle replay recording",
            genericName: "Replay",
            icon: "arrows-clockwise",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                RecordingService.toggleReplay();
            }
        },
        {
            name: "Save replay",
            genericName: "Replay",
            icon: "floppy-disk",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                RecordingService.saveReplay();
            }
        },
        {
            name: "Dashboard",
            genericName: "Quickshell",
            icon: "cards-three",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("dashboard");
            }
        },
        {
            name: "Wallpapers",
            genericName: "Quickshell",
            icon: "image",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("wallpaperSelector");
            }
        },
        {
            name: "Audio Mixer",
            genericName: "Quickshell",
            icon: "faders",
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
            icon: "bell",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.viewChangeRequested("notifications");
            }
        },
        {
            name: "Next Track",
            genericName: "MPRIS",
            icon: "skip-forward",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.mpris.next();
            }
        },
        {
            name: "Power Off",
            genericName: "Power",
            icon: "power",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                Quickshell.execDetached(["systemctl", "poweroff"])
            }
        },
        {
            name: "Reboot",
            genericName: "Power",
            icon: "arrows-clockwise",
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
            icon: "skip-back",
            iconType: LauncherProvider.IconType.Material,
            execute: function() {
                root.svc.mpris.previous();
            }
        },
        {
            name: "Play/Pause Track",
            genericName: "MPRIS",
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
