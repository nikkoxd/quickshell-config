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
        value: Config.notifications.doNotDisturb
        onChecked: value => Config.notifications.doNotDisturb = value
        type: SettingsOption.Type.Switch
    }

    SettingsSection {
        text: "Sound"
    }

    SettingsOption {
        title: "Play a sound"
        value: Config.notifications.sound
        onChecked: value => Config.notifications.sound = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Sound"
        value: SoundService.resolve(Config.notifications.soundFile)
        options: SoundService.names
        // Picking is the only way to hear the difference, so play it back as
        // it is chosen instead of hiding a preview button beside the list.
        onEdited: value => {
            Config.notifications.soundFile = value;
            SoundService.play(value, Config.notifications.soundVolume);
        }
        type: SettingsOption.Type.ComboBox
    }

    SettingsListOption {
        title: "Apps that chime themselves"
        placeholder: "Discord"
        values: Config.notifications.silentApps
        onUpdated: values => Config.notifications.silentApps = values
    }

    SettingsOption {
        title: "Volume"
        units: "%"
        value: Config.notifications.soundVolume
        onEdited: value => {
            const volume = Math.max(0, Math.min(100, parseInt(value) || 0));
            Config.notifications.soundVolume = volume;
            SoundService.play(Config.notifications.soundFile, volume);
        }
        type: SettingsOption.Type.TextField
    }
}
