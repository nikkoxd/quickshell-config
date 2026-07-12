import Quickshell
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: column.implicitWidth + 20
    implicitHeight: column.implicitHeight + 20
    dismissable: false
    focused: true
    displayInFullscreen: true

    property string query: ""
    property var mode: Launcher.Mode.Normal

    enum Mode {
        Normal,
        Themes
    }

    property var customEntries: [
        {
            name: "Dashboard",
            genericName: "Quickshell",
            icon: "dashboard",
            execute: function() {
                root.viewChangeRequested("dashboard");
            }
        },
        {
            name: "Wallpapers",
            genericName: "Quickshell",
            icon: "wallpaper",
            execute: function() {
                root.viewChangeRequested("wallpapers");
            }
        },
        {
            name: "Audio Mixer",
            genericName: "Quickshell",
            icon: "audio-volume-high",
            execute: function() {
                root.viewChangeRequested("mixer");
            }
        },
        {
            name: "Bluetooth",
            genericName: "Quickshell",
            icon: "bluetooth",
            execute: function() {
                root.viewChangeRequested("bluetooth");
            }
        },
        {
            name: "Notifications",
            genericName: "Quickshell",
            icon: "notification",
            execute: function() {
                root.viewChangeRequested("notifications");
            }
        },
        {
            name: "Bar Settings",
            genericName: "Quickshell",
            icon: "settings",
            execute: function() {
                root.viewChangeRequested("settings");
            }
        },
        {
            name: "Select Theme",
            genericName: "Quickshell",
            icon: "color_lens",
            preventClose: true,
            execute: function() {
                root.mode = Launcher.Mode.Themes;
                searchInput.text = "";
            }
        },
        {
            name: "Next Track",
            genericName: "MPRIS",
            icon: "skip_next",
            execute: function() {
                MprisService.next();
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
                MprisService.previous();
            }
        },
        {
            name: "Play/Pause Track",
            genericName: "MPRIS",
            icon: "play_arrow",
            execute: function() {
                MprisService.togglePlaying();
            }
        },
    ]

    function launchSelected() {
        if (list.currentItem && list.currentItem.modelData) {
            const currentData = list.currentItem.modelData;
            currentData.execute();
            if (currentData.preventClose !== true)
                root.closeRequested();
        }
    }

    function fuzzyScore(query, str) {
        if (!query)
            return 1;
        if (!str)
            return 0;

        const q = query.toLowerCase();
        const s = str.toLowerCase();
        let score = 0;
        let qIdx = 0;
        let lastMatch = -1;

        for (let i = 0; i < s.length && qIdx < q.length; i++) {
            if (s[i] === q[qIdx]) {
                // Bonus for consecutive matches
                if (lastMatch === i - 1)
                    score += 2;
                // Bonus for matching at word boundaries
                if (i === 0 || s[i - 1] === ' ' || s[i - 1] === '-')
                    score += 3;
                lastMatch = i;
                qIdx++;
            }
        }

        // Return 0 if not all characters matched
        if (qIdx < q.length)
            return 0;

        // Penalize length difference (prefer shorter matches)
        return score / s.length;
    }

    function evalMath(expr) {
        // Strip spaces and convert ^ to ** for exponentiation
        const clean = expr.replace(/\s+/g, '').replace(/\^/g, '**');
        // Only allow digits and math operators
        if (!/^[\d+\-*/().]+$/.test(clean))
            return null;
        // Require at least one operator so plain numbers (e.g. "1password") don't trigger
        if (!/[+\-*/()]/.test(clean))
            return null;
        try {
            const result = eval(clean);
            if (typeof result === 'number' && isFinite(result)) {
                return result;
            }
        } catch (e) {}
        return null;
    }

    FolderListModel {
        id: themesModel
        folder: Qt.resolvedUrl("../../Themes")
        nameFilters: ["*.json"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    Column {
        id: column
        spacing: 10
        y: 10
        anchors.horizontalCenter: parent.horizontalCenter

        Row {
            spacing: 2

            ThemedText {
                id: icon
                text: root.mode === Launcher.Mode.Normal ? "search" : "palette"
                icon: true
                font.pixelSize: Config.theme.fontSize * 1.15
                anchors.verticalCenter: parent.verticalCenter

                onTextChanged: iconAnim.restart()

                SequentialAnimation {
                    id: iconAnim
                    NumberAnimation {
                        target: icon
                        property: "scale"
                        from: 1
                        to: 0
                        duration: 0
                    }
                    NumberAnimation {
                        target: icon
                        property: "scale"
                        from: 0
                        to: 1
                        duration: 350
                        easing.type: Easing.InOutQuart
                    }
                }
            }

            TextField {
                id: searchInput
                focus: true
                activeFocusOnTab: true
                placeholderText: root.mode === Launcher.Mode.Normal ? "Search..." : "Search themes..."
                color: Config.colorscheme.fg
                placeholderTextColor: Config.colorscheme.fg
                selectionColor: Config.colorscheme.accent
                selectedTextColor: Config.colorscheme.bg
                font.family: Config.theme.fontFamily
                font.pixelSize: Config.theme.fontSize
                background: Item {
                    implicitWidth: 400
                    implicitHeight: 20
                }
                onTextChanged: root.query = text.toLowerCase().trim()
                Component.onCompleted: forceActiveFocus()
                Keys.onEscapePressed: root.closeRequested()
                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;

                    if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
                        event.accepted = true;
                        if (list.currentIndex > 0)
                            list.currentIndex--;
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
                        event.accepted = true;
                        if (list.currentIndex < list.count - 1)
                            list.currentIndex++;
                    } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                        event.accepted = true;
                        root.launchSelected();
                    }
                }
            }
        }

        ScriptModel {
            id: filtered
            values: {
                const q = root.query;

                if (root.mode === Launcher.Mode.Themes) {
                    const themes = [];
                    for (let i = 0; i < themesModel.count; i++) {
                        const theme = themesModel.get(i, "fileBaseName");
                        themes.push({
                            name: theme,
                            genericName: "Theme",
                            icon: "color_lens",
                            execute: function() {
                                Config.theme.colorscheme = theme;
                                root.closeRequested();
                            }
                        });
                    }

                    if (!q) return themes;

                    return themes.map(t => {
                        return { entry: t, score: fuzzyScore(q, t.name) };
                    }).filter(item => item.score > 0)
                        .sort((a, b) => b.score - a.score)
                        .map(item => item.entry);
                }

                if (!q && !Config.launcher.showResultsWithEmptyQuery)
                    return [];

                const all = [...DesktopEntries.applications.values, ...root.customEntries];
                const scored = all.map(d => {
                    const nameScore = d.name ? fuzzyScore(q, d.name) : 0;
                    const genericScore = d.genericName ? fuzzyScore(q, d.genericName) : 0;
                    return {
                        entry: d,
                        score: Math.max(nameScore, genericScore)
                    };
                }).filter(item => item.score > 0).sort((a, b) => b.score - a.score);

                const results = scored.map(item => item.entry);

                const calcResult = root.evalMath(q);
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

        ListView {
            id: list
            clip: true
            model: filtered.values
            width: parent.width
            height: Math.min(contentHeight, 200)
            spacing: 5
            delegate: LauncherEntry {}
        }
    }
}
