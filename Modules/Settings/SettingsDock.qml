pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Widgets
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
            text: "Dock"
        }

        SettingsOption {
            title: "Display dock"
            value: Config.dock.enabled
            onChecked: value => Config.dock.enabled = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Show on hover only"
            value: Config.dock.onlyOnHover
            onChecked: value => Config.dock.onlyOnHover = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Show when workspace is clear"
            value: Config.dock.showWhenWorkspaceClear
            onChecked: value => Config.dock.showWhenWorkspaceClear = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Hover hotzone height"
            units: "px"
            value: Config.dock.hotzoneHeight
            onEdited: value => Config.dock.hotzoneHeight = parseInt(value)
            type: SettingsOption.Type.TextField
        }
    }

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Icons"
        }

        SettingsOption {
            title: "Tint icons with theme"
            value: Config.dock.coloredIcons
            onChecked: value => Config.dock.coloredIcons = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Icon size"
            units: "px"
            value: Config.dock.iconSize
            onEdited: value => Config.dock.iconSize = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Icon spacing"
            units: "px"
            value: Config.dock.spacing
            onEdited: value => Config.dock.spacing = parseInt(value)
            type: SettingsOption.Type.TextField
        }
    }

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Pinned apps"
        }

        ThemedText {
            text: "Right-click an icon in the dock to pin it. Drag icons to reorder."
            opacity: 0.7
        }

        Repeater {
            model: DockService.pinned

            RowLayout {
                id: pin

                required property string modelData

                readonly property DesktopEntry entry: DesktopEntries.heuristicLookup(pin.modelData)

                spacing: 10
                Layout.fillWidth: true

                IconImage {
                    implicitSize: 24
                    asynchronous: true
                    source: Quickshell.iconPath(pin.entry ? pin.entry.icon : pin.modelData, "application-x-executable")
                }

                ThemedText {
                    text: pin.entry ? pin.entry.name : pin.modelData
                    font.pixelSize: 16
                }

                Item {
                    Layout.fillWidth: true
                }

                ThemedText {
                    icon: true
                    text: "x-circle"
                    font.pixelSize: 18
                    color: unpinHover.hovered ? Config.colorscheme.accent : Config.colorscheme.fg

                    HoverHandler {
                        id: unpinHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: DockService.setPinned(pin.modelData, false)
                    }
                }
            }
        }
    }
}
