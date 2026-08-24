import Quickshell.Services.Pipewire
import QtQuick
import qs.Core

View {
    id: root
    implicitWidth: root.contentWidth + 30
    implicitHeight: column.implicitHeight + 30
    focused: true
    dismissable: false
    displayInFullscreen: true
    closeOnUnhover: true

    readonly property int contentWidth: 310

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    PwNodeLinkTracker {
        id: linkTracker
        node: Pipewire.defaultAudioSink
    }

    Column {
        id: column
        width: root.contentWidth
        anchors.centerIn: parent
        spacing: 10

        ViewHeader {
            width: parent.width
            text: "Mixer"

            IconButton {
                icon: "speaker-high"
                activeIcon: "speaker-slash"
                active: Pipewire.defaultAudioSink?.audio.muted ?? false
                onClicked: {
                    if (Pipewire.defaultAudioSink)
                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                }
            }

            IconButton {
                icon: "microphone"
                activeIcon: "microphone-slash"
                active: Pipewire.defaultAudioSource?.audio.muted ?? false
                onClicked: {
                    if (Pipewire.defaultAudioSource)
                        Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
                }
            }
        }

        // The default sink and source, above the per-application streams that
        // feed into them.
        Slider {
            width: parent.width
            icon: "speaker-high"
            trackColor: Config.colorscheme.bg
            value: Pipewire.defaultAudioSink?.audio.volume ?? 0
            onValueChanged: {
                if (Pipewire.defaultAudioSink)
                    Pipewire.defaultAudioSink.audio.volume = value;
            }
        }

        Slider {
            width: parent.width
            icon: "microphone"
            trackColor: Config.colorscheme.bg
            value: Pipewire.defaultAudioSource?.audio.volume ?? 0
            onValueChanged: {
                if (Pipewire.defaultAudioSource)
                    Pipewire.defaultAudioSource.audio.volume = value;
            }
        }

        ListView {
            id: list
            width: parent.width
            height: contentHeight
            interactive: false
            spacing: 10
            model: linkTracker.linkGroups
            delegate: MixerEntry {
                required property PwLinkGroup modelData

                width: list.width
                node: modelData.source
            }
        }
    }
}
