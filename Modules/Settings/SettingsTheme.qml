import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    SettingsSection {
        text: "Theme"
    }

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

    SettingsSection {
        text: "Iris"
    }

    SettingsOption {
        title: "Enabled"
        value: Config.iris.enabled
        onChecked: value => Config.iris.enabled = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Auto light/dark mode"
        value: Config.iris.autoMode
        onChecked: value => Config.iris.autoMode = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Dark mode"
        value: Config.iris.dark
        onChecked: value => Config.iris.dark = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Commands to run after"
        value: Config.iris.after
        onEdited: value => Config.iris.after = value
        type: SettingsOption.Type.TextField
    }

}
