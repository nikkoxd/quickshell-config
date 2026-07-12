import Quickshell.Services.Pipewire
import QtQuick
import qs.Core

Column {
    id: root
    spacing: 10

    signal viewChangeRequested(view: string)

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    ThemedText {
        text: "Control Center"
        font.pixelSize: Config.theme.fontSize * 1.15
    }

    ControlCenterButton {
        active: !Pipewire.defaultAudioSink.audio.muted
        wide: true
        icon: "volume_up"
        text: "Audio"
        status: Pipewire.defaultAudioSink.description
        onClicked: {
            root.viewChangeRequested("audioMixer");
        }
        onIconClicked: {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
    }

    Row {
        spacing: 10

        ControlCenterButton {
            active: true
            text: "Bluetooth"
            icon: "bluetooth"
            status: "Connected"
        }

        ControlCenterButton {
            active: true
            text: "Notifications"
            icon: "notifications"
            status: "Enabled"
        }
    }
}
