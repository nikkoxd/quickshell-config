import Quickshell
import qs.Core

LauncherProvider {
    id: root
    providerId: "default"
    headerIcon: "search"
    placeholder: "Search..."

    property var customEntries: [
        {
            name: "Dashboard",
            genericName: "Quickshell",
            icon: "dashboard",
            execute: function() {
                root.svc.viewChangeRequested("dashboard");
            }
        },
        {
            name: "Wallpapers",
            genericName: "Quickshell",
            icon: "wallpaper",
            execute: function() {
                root.svc.viewChangeRequested("wallpapers");
            }
        },
        {
            name: "Audio Mixer",
            genericName: "Quickshell",
            icon: "audio-volume-high",
            execute: function() {
                root.svc.viewChangeRequested("mixer");
            }
        },
        {
            name: "Bluetooth",
            genericName: "Quickshell",
            icon: "bluetooth",
            execute: function() {
                root.svc.viewChangeRequested("bluetooth");
            }
        },
        {
            name: "Notifications",
            genericName: "Quickshell",
            icon: "notification",
            execute: function() {
                root.svc.viewChangeRequested("notifications");
            }
        },
        {
            name: "Bar Settings",
            genericName: "Quickshell",
            icon: "settings",
            execute: function() {
                root.svc.viewChangeRequested("settings");
            }
        },
        {
            name: "Select Theme",
            genericName: "Quickshell",
            icon: "color_lens",
            preventClose: true,
            execute: function() {
                root.svc.provider = "themes";
            }
        },
        {
            name: "Next Track",
            genericName: "MPRIS",
            icon: "skip_next",
            execute: function() {
                root.svc.mpris.next();
            }
        },
        {
            name: "Power Off",
            genericName: "Power",
            icon: "power_settings_new",
            execute: function() {
                Quickshell.execDetached(["systemctl", "poweroff"])
            }
        },
        {
            name: "Reboot",
            genericName: "Power",
            icon: "restart_alt",
            execute: function() {
                Quickshell.execDetached(["systemctl", "reboot"])
            }
        },
        {
            name: "Suspend",
            genericName: "Power",
            icon: "pause",
            execute: function() {
                Quickshell.execDetached(["systemctl", "suspend"])
            }
        },
        {
            name: "Lock",
            genericName: "Power",
            icon: "lock",
            execute: function() {
                Quickshell.execDetached(["loginctl", "lock-session"])
            }
        },
        {
            name: "Previous Track",
            genericName: "MPRIS",
            icon: "skip_previous",
            execute: function() {
                root.svc.mpris.previous();
            }
        },
        {
            name: "Play/Pause Track",
            genericName: "MPRIS",
            icon: "play_arrow",
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
        const scored = all.map(d => {
            const nameScore = d.name ? root.svc.fuzzyScore(q, d.name) : 0;
            const genericScore = d.genericName ? root.svc.fuzzyScore(q, d.genericName) : 0;
            return {
                entry: d,
                score: Math.max(nameScore, genericScore)
            };
        }).filter(item => item.score > 0).sort((a, b) => b.score - a.score);

        const results = scored.map(item => item.entry);

        const calcResult = root.svc.evalMath(q);
        if (calcResult !== null) {
            const calcEntry = {
                name: q + " = " + calcResult,
                genericName: "Calculator",
                execute: function () {
                    Quickshell.execDetached(["wl-copy", calcResult.toString()]);
                    console.log("Calculator result:", calcResult);
                }
            };
            results.unshift(calcEntry);
        }

        return results;
    }
}
