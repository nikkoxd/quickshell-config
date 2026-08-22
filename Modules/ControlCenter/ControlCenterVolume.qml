import Quickshell.Services.Pipewire
import QtQuick
import qs.Core

Row {
    id: root
    spacing: 10

    required property int contentHeight

    Slider {
        icon: "speaker-high"
        vertical: true
        height: root.contentHeight
        value: Pipewire.defaultAudioSink.audio.volume
        onValueChanged: {
            if (Pipewire.defaultAudioSink) {
                Pipewire.defaultAudioSink.audio.volume = value;
            }
        }
    }

    Slider {
        icon: "microphone"
        vertical: true
        height: root.contentHeight
        value: Pipewire.defaultAudioSource.audio.volume
        onValueChanged: {
            if (Pipewire.defaultAudioSource) {
                Pipewire.defaultAudioSource.audio.volume = value;
            }
        }
    }
}
