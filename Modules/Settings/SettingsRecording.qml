import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 30
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Recordings"
        }

        SettingsOption {
            title: "Recordings folder"
            value: SettingsDraft.get("recorder", "recordingsFolder")
            onEdited: value => SettingsDraft.set("recorder", "recordingsFolder", value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Framerate"
            units: "FPS"
            value: SettingsDraft.get("recorder", "recordingFramerate")
            onEdited: value => SettingsDraft.set("recorder", "recordingFramerate", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Audio in recordings"
            value: SettingsDraft.get("recorder", "recordingAudio")
            onChecked: value => SettingsDraft.set("recorder", "recordingAudio", value)
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Microphone in recordings"
            value: SettingsDraft.get("recorder", "recordingMicrophone")
            onChecked: value => SettingsDraft.set("recorder", "recordingMicrophone", value)
            type: SettingsOption.Type.Switch
        }
    }

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Replays"
        }

        SettingsOption {
            title: "Replays folder"
            value: SettingsDraft.get("recorder", "replaysFolder")
            onEdited: value => SettingsDraft.set("recorder", "replaysFolder", value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Replay duration"
            units: "s"
            value: SettingsDraft.get("recorder", "replayDuration")
            onEdited: value => SettingsDraft.set("recorder", "replayDuration", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Auto-start replay"
            value: SettingsDraft.get("recorder", "replayAutostart")
            onChecked: value => SettingsDraft.set("recorder", "replayAutostart", value)
            type: SettingsOption.Type.Switch
        }
    }

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Screenshots"
        }

        SettingsOption {
            title: "Screenshots folder"
            value: SettingsDraft.get("recorder", "screenshotsFolder")
            onEdited: value => SettingsDraft.set("recorder", "screenshotsFolder", value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Save screenshots to disk"
            value: SettingsDraft.get("recorder", "screenshotSave")
            onChecked: value => SettingsDraft.set("recorder", "screenshotSave", value)
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Copy screenshots to clipboard"
            value: SettingsDraft.get("recorder", "screenshotCopy")
            onChecked: value => SettingsDraft.set("recorder", "screenshotCopy", value)
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Freeze the screen while selecting"
            value: SettingsDraft.get("recorder", "screenshotFreeze")
            onChecked: value => SettingsDraft.set("recorder", "screenshotFreeze", value)
            type: SettingsOption.Type.Switch
        }
    }

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "OCR"
        }

        SettingsOption {
            title: "OCR language"
            value: SettingsDraft.get("recorder", "ocrLanguage")
            onEdited: value => SettingsDraft.set("recorder", "ocrLanguage", value)
            type: SettingsOption.Type.TextField
        }
    }
}
