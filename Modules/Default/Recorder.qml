import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: container.implicitWidth + 20
    implicitHeight: container.implicitHeight + 20
    dismissable: false
    focused: true
    displayInFullscreen: true
    closeOnUnhover: true

    component RecorderButton: Rectangle {
        id: button
        color: active ? Config.colorscheme.accent : hoverHandler.hovered ? Config.colorscheme.surface : "transparent"
        width: 40
        height: 40
        radius: 10

        signal tapped()
        required property string icon
        property string iconColor: Config.colorscheme.fg
        property bool active: false

        TapHandler { onTapped: button.tapped() }
        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing: Easing.OutQuart
            }
        }

        ThemedText {
            text: button.icon
            color: button.active ? Config.colorscheme.bg : button.iconColor
            icon: true
            font.pixelSize: 18
            anchors.centerIn: parent

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing: Easing.OutQuart
                }
            }
        }
    }

    Row {
        id: container
        spacing: 20
        anchors.centerIn: parent

        Row {
            spacing: 5
            RecorderButton {
                icon: "selection"
            }
            RecorderButton {
                icon: "app-window"
            }
            RecorderButton {
                icon: "monitor"
            }
        }

        Row {
            spacing: 5
            RecorderButton {
                icon: "video-camera"
                active: RecordingService.recording
                // Close either way: out of the way of what's being recorded when
                // starting, and so the "finished" notification isn't suppressed
                // (this view is not dismissable) when stopping.
                onTapped: {
                    RecordingService.toggleRecording();
                    root.closeRequested();
                }
            }
            RecorderButton {
                icon: "arrows-clockwise"
                active: RecordingService.replayRunning
                onTapped: RecordingService.toggleReplay()
            }
            RecorderButton {
                icon: "floppy-disk"
                visible: RecordingService.replayRunning
                // Same reason as above: the panel has to go for the notification
                // to be shown.
                onTapped: {
                    RecordingService.saveReplay();
                    root.closeRequested();
                }
            }
        }
    }
}
