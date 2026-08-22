import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.Core

View {
    id: root
    implicitWidth: volume.implicitWidth + 30
    implicitHeight: Config.island.height
    displayInFullscreen: true
    property bool isExpanded: parent !== null

    Timer {
        id: timer
        interval: 2000
        running: true
        onTriggered: {
            root.closeRequested();
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                timer.running = false;
            } else {
                timer.running = true;
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.LeftButton) {
                root.viewChangeRequested("dashboard");
            } else {
                root.viewChangeRequested("controlCenter");
            }
        }
    }

    RowLayout {
        id: volume
        spacing: 15
        anchors.centerIn: parent

        ThemedText {
            text: "speaker-high"
            icon: true
        }

        Slider {
            id: volumeSlider
            implicitHeight: 5
            implicitWidth: 200
            radius: 100
            trackColor: Config.colorscheme.surface
            value: Pipewire.defaultAudioSink.audio.volume
            onValueChanged: {
                if (Pipewire.defaultAudioSink) {
                    Pipewire.defaultAudioSink.audio.volume = value;
                }
            }
        }

        // wrap in an item to set fixed width
        Item {
            width: 30
            height: childrenRect.height
            ThemedText {
                text: `${Math.floor(Pipewire.defaultAudioSink.audio.volume * 100)}%`
            }
        }
    }
}
