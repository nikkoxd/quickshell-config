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
            value: Config.recorder.recordingsFolder
            onEdited: value => Config.recorder.recordingsFolder = value
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Framerate"
            units: "FPS"
            value: Config.recorder.recordingFramerate
            onEdited: value => Config.recorder.recordingFramerate = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Audio in recordings"
            value: Config.recorder.recordingAudio
            onChecked: value => Config.recorder.recordingAudio = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Microphone in recordings"
            value: Config.recorder.recordingMicrophone
            onChecked: value => Config.recorder.recordingMicrophone = value
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
            value: Config.recorder.replaysFolder
            onEdited: value => Config.recorder.replaysFolder = value
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Replay duration"
            units: "s"
            value: Config.recorder.replayDuration
            onEdited: value => Config.recorder.replayDuration = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Auto-start replay"
            value: Config.recorder.replayAutostart
            onChecked: value => Config.recorder.replayAutostart = value
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
            value: Config.recorder.screenshotsFolder
            onEdited: value => Config.recorder.screenshotsFolder = value
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Save screenshots to disk"
            value: Config.recorder.screenshotSave
            onChecked: value => Config.recorder.screenshotSave = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Copy screenshots to clipboard"
            value: Config.recorder.screenshotCopy
            onChecked: value => Config.recorder.screenshotCopy = value
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
            value: Config.recorder.ocrLanguage
            onEdited: value => Config.recorder.ocrLanguage = value
            type: SettingsOption.Type.TextField
        }
    }
}
