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
        title: "Colorscheme"
        value: Config.theme.colorscheme
        onEdited: value => Config.theme.colorscheme = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Font family"
        value: Config.theme.fontFamily
        onEdited: value => Config.theme.fontFamily = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Font weight"
        value: Config.theme.fontWeight
        onEdited: value => Config.theme.fontWeight = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Font size"
        units: "px"
        value: Config.theme.fontSize
        onEdited: value => Config.theme.fontSize = parseInt(value)
        type: SettingsOption.Type.TextField
    }
}
