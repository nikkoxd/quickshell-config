import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
            text: "volume_up"
            icon: true
        }

        Slider {
            id: volumeSlider
            height: 5
            implicitWidth: 200
            handle: Item {}
            background: ClippingRectangle {
                color: Config.colorscheme.surface
                width: volumeSlider.availableWidth
                radius: 100
                clip: true
                Rectangle {
                    color: Config.colorscheme.accent
                    height: parent.height
                    width: volumeSlider.visualPosition * volumeSlider.width
                    radius: 100

                    Behavior on width {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
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
