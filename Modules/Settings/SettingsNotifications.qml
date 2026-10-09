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
        text: "Notifications"
    }

    SettingsOption {
        title: "Do not disturb"
        value: SettingsDraft.get("notifications", "doNotDisturb")
        onChecked: value => SettingsDraft.set("notifications", "doNotDisturb", value)
        type: SettingsOption.Type.Switch
    }

    SettingsSection {
        text: "Sound"
    }

    SettingsOption {
        title: "Play a sound"
        value: SettingsDraft.get("notifications", "sound")
        onChecked: value => SettingsDraft.set("notifications", "sound", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Sound"
        value: SoundService.resolve(SettingsDraft.get("notifications", "soundFile"))
        options: SoundService.names
        // Picking is the only way to hear the difference, so play it back as
        // it is chosen instead of hiding a preview button beside the list.
        onEdited: value => {
            SettingsDraft.set("notifications", "soundFile", value);
            SoundService.play(value, SettingsDraft.get("notifications", "soundVolume"));
        }
        type: SettingsOption.Type.ComboBox
    }

    SettingsListOption {
        title: "Apps that chime themselves"
        placeholder: "Discord"
        values: SettingsDraft.get("notifications", "silentApps")
        onUpdated: values => SettingsDraft.set("notifications", "silentApps", values)
    }

    SettingsOption {
        title: "Volume"
        maximum: 100
        units: "%"
        value: SettingsDraft.get("notifications", "soundVolume")
        onEdited: value => {
            const volume = Math.max(0, Math.min(100, parseInt(value) || 0));
            SettingsDraft.set("notifications", "soundVolume", volume);
            SoundService.play(SettingsDraft.get("notifications", "soundFile"), volume);
        }
        type: SettingsOption.Type.TextField
    }
}
