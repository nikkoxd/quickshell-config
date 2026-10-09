pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

ColumnLayout {
    id: root

    // Asked top to bottom; the first one that has the track wins.
    readonly property var providers: LyricsService.normalizeProviders(SettingsDraft.get("island", "lyricsProviders"))

    // Swap the provider at `index` with the one `delta` places away.
    function moveProvider(index, delta) {
        const next = root.providers.slice();
        const target = index + delta;
        if (target < 0 || target >= next.length)
            return;
        const moved = next[index];
        next[index] = next[target];
        next[target] = moved;
        SettingsDraft.set("island", "lyricsProviders", next);
    }

    function setProviderEnabled(index, enabled) {
        const next = root.providers.map(p => ({
                    name: p.name,
                    enabled: p.enabled
                }));
        next[index].enabled = enabled;
        SettingsDraft.set("island", "lyricsProviders", next);
    }

    spacing: 30
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Island"
        }

        SettingsOption {
            title: "Height"
            units: "px"
            value: SettingsDraft.get("island", "height")
            onEdited: value => SettingsDraft.set("island", "height", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Outer margins"
            units: "px"
            value: SettingsDraft.get("island", "margins")
            onEdited: value => SettingsDraft.set("island", "margins", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Inner padding"
            units: "px"
            value: SettingsDraft.get("island", "padding")
            onEdited: value => SettingsDraft.set("island", "padding", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Corner radius"
            units: "px"
            value: SettingsDraft.get("island", "radius")
            onEdited: value => SettingsDraft.set("island", "radius", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Hover open delay"
            step: 10
            units: "ms"
            value: SettingsDraft.get("island", "hoverOpenDelay")
            onEdited: value => SettingsDraft.set("island", "hoverOpenDelay", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Hover close delay"
            step: 10
            units: "ms"
            value: SettingsDraft.get("island", "hoverCloseDelay")
            onEdited: value => SettingsDraft.set("island", "hoverCloseDelay", parseInt(value))
            type: SettingsOption.Type.TextField
        }
    }

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Lyrics"
        }

        SettingsOption {
            title: "Display lyrics"
            value: SettingsDraft.get("island", "displayLyrics")
            onChecked: value => SettingsDraft.set("island", "displayLyrics", value)
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Delay"
            step: 10
            minimum: -Infinity
            units: "ms"
            value: SettingsDraft.get("island", "lyricsOffset")
            onEdited: value => SettingsDraft.set("island", "lyricsOffset", parseInt(value) || 0)
            type: SettingsOption.Type.TextField
        }

        ThemedText {
            text: "Providers"
            font.pixelSize: 16
        }

        Repeater {
            model: root.providers

            RowLayout {
                id: provider

                required property int index
                required property var modelData

                spacing: 10
                Layout.fillWidth: true

                ThemedText {
                    text: ({
                            kugou: "Kugou",
                            lrclib: "LRCLIB"
                        })[provider.modelData.name] || provider.modelData.name
                    font.pixelSize: 16
                    opacity: provider.modelData.enabled ? 1 : 0.5
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: "caret-up"
                    opacity: provider.index > 0 ? 1 : 0.3
                    onClicked: root.moveProvider(provider.index, -1)
                }

                IconButton {
                    icon: "caret-down"
                    opacity: provider.index < root.providers.length - 1 ? 1 : 0.3
                    onClicked: root.moveProvider(provider.index, 1)
                }

                Toggle {
                    checked: provider.modelData.enabled
                    onToggled: value => root.setProviderEnabled(provider.index, value)
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 65
                }
            }
        }
    }
}
