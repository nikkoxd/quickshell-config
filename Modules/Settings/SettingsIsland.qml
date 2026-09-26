pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

ColumnLayout {
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
            value: Config.island.height
            onEdited: value => Config.island.height = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Outer margins"
            units: "px"
            value: Config.island.margins
            onEdited: value => Config.island.margins = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Inner padding"
            units: "px"
            value: Config.island.padding
            onEdited: value => Config.island.padding = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Corner radius"
            units: "px"
            value: Config.island.radius
            onEdited: value => Config.island.radius = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Hover open delay"
            units: "ms"
            value: Config.island.hoverOpenDelay
            onEdited: value => Config.island.hoverOpenDelay = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Hover close delay"
            units: "ms"
            value: Config.island.hoverCloseDelay
            onEdited: value => Config.island.hoverCloseDelay = parseInt(value)
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
            value: Config.island.displayLyrics
            onChecked: value => Config.island.displayLyrics = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Delay"
            units: "ms"
            value: Config.island.lyricsOffset
            onEdited: value => Config.island.lyricsOffset = parseInt(value) || 0
            type: SettingsOption.Type.TextField
        }

        // Asked top to bottom; the first one that has the track wins.
        ThemedText {
            text: "Providers"
            font.pixelSize: 16
        }

        Repeater {
            model: LyricsService.providers

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
                    onClicked: LyricsService.moveProvider(provider.index, -1)
                }

                IconButton {
                    icon: "caret-down"
                    opacity: provider.index < LyricsService.providers.length - 1 ? 1 : 0.3
                    onClicked: LyricsService.moveProvider(provider.index, 1)
                }

                Toggle {
                    checked: provider.modelData.enabled
                    onToggled: value => LyricsService.setProviderEnabled(provider.index, value)
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 65
                }
            }
        }
    }
}
