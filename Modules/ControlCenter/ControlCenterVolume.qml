import Quickshell.Services.Pipewire
import QtQuick

Column {
    spacing: 10

    ControlCenterSlider {
        icon: "volume_up"
        value: Pipewire.defaultAudioSink.audio.volume
        onValueChanged: {
            if (Pipewire.defaultAudioSink) {
                Pipewire.defaultAudioSink.audio.volume = value;
            }
        }
    }

    ControlCenterSlider {
        icon: "mic"
        value: Pipewire.defaultAudioSource.audio.volume
        onValueChanged: {
            if (Pipewire.defaultAudioSource) {
                Pipewire.defaultAudioSource.audio.volume = value;
            }
        }
    }
}
