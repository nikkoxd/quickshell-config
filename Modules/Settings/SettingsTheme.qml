import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

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
        options: ThemeService.names
        onEdited: value => Config.theme.colorscheme = value
        type: SettingsOption.Type.ComboBox
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

    SettingsListOption {
        title: "Commands to run after"
        placeholder: "emacsclient -e \"(load-theme 'iris t)\""
        values: Config.iris.after
        onUpdated: values => Config.iris.after = values
    }

    SettingsSection {
        text: "Matugen"
    }

    SettingsOption {
        title: "Auto light/dark mode"
        value: Config.matugen.autoMode
        onChecked: value => Config.matugen.autoMode = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Dark mode"
        value: Config.matugen.dark
        onChecked: value => Config.matugen.dark = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Scheme type"
        value: Config.matugen.scheme
        onEdited: value => Config.matugen.scheme = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Source color preference"
        value: Config.matugen.prefer
        onEdited: value => Config.matugen.prefer = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Contrast"
        value: Config.matugen.contrast
        onEdited: value => Config.matugen.contrast = parseFloat(value) || 0
        type: SettingsOption.Type.TextField
    }

    SettingsListOption {
        title: "Commands to run after"
        placeholder: "makoctl reload"
        values: Config.matugen.after
        onUpdated: values => Config.matugen.after = values
    }

}
