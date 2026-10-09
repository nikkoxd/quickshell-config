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
        value: SettingsDraft.get("theme", "colorscheme")
        options: ThemeService.names
        onEdited: value => SettingsDraft.set("theme", "colorscheme", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Font family"
        value: SettingsDraft.get("theme", "fontFamily")
        onEdited: value => SettingsDraft.set("theme", "fontFamily", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Font weight"
        value: SettingsDraft.get("theme", "fontWeight")
        onEdited: value => SettingsDraft.set("theme", "fontWeight", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Font size"
        units: "px"
        value: SettingsDraft.get("theme", "fontSize")
        onEdited: value => SettingsDraft.set("theme", "fontSize", parseInt(value))
        type: SettingsOption.Type.TextField
    }

    SettingsSection {
        text: "Iris"
    }

    SettingsOption {
        title: "Auto light/dark mode"
        value: SettingsDraft.get("iris", "autoMode")
        onChecked: value => SettingsDraft.set("iris", "autoMode", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Dark mode"
        value: SettingsDraft.get("iris", "dark")
        onChecked: value => SettingsDraft.set("iris", "dark", value)
        type: SettingsOption.Type.Switch
    }

    SettingsListOption {
        title: "Commands to run after"
        placeholder: "emacsclient -e \"(load-theme 'iris t)\""
        values: SettingsDraft.get("iris", "after")
        onUpdated: values => SettingsDraft.set("iris", "after", values)
    }

    SettingsSection {
        text: "Matugen"
    }

    SettingsOption {
        title: "Auto light/dark mode"
        value: SettingsDraft.get("matugen", "autoMode")
        onChecked: value => SettingsDraft.set("matugen", "autoMode", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Dark mode"
        value: SettingsDraft.get("matugen", "dark")
        onChecked: value => SettingsDraft.set("matugen", "dark", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Scheme type"
        value: SettingsDraft.get("matugen", "scheme")
        onEdited: value => SettingsDraft.set("matugen", "scheme", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Source color preference"
        value: SettingsDraft.get("matugen", "prefer")
        onEdited: value => SettingsDraft.set("matugen", "prefer", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Contrast"
        value: SettingsDraft.get("matugen", "contrast")
        onEdited: value => SettingsDraft.set("matugen", "contrast", parseFloat(value) || 0)
        type: SettingsOption.Type.TextField
    }

    SettingsListOption {
        title: "Commands to run after"
        placeholder: "makoctl reload"
        values: SettingsDraft.get("matugen", "after")
        onUpdated: values => SettingsDraft.set("matugen", "after", values)
    }

}
