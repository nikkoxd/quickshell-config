import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

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
        title: "KeePassXC vault path"
        value: Config.island.keepassVault
        onEdited: value => Config.island.keepassVault = value
        type: SettingsOption.Type.TextField
    }
}
