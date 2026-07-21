import Quickshell.Io
import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: lyrics.implicitWidth + Config.island.padding * 2
    implicitHeight: Config.island.height

    Connections {
        target: LyricsService
        function onCurrentTextChanged() {
            lyrics.pendingText = LyricsService.currentText;
            textChangeAnim.restart();
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

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: {
            root.defaultViewChangeRequested("clock");
            root.viewChangeRequested("clock");
        }
    }

    ThemedText {
        id: lyrics
        anchors.centerIn: parent
        property string pendingText: ""
        Component.onCompleted: lyrics.text = LyricsService.currentText;

        SequentialAnimation {
            id: textChangeAnim

            ParallelAnimation {
                NumberAnimation {
                    target: lyrics
                    property: "opacity"
                    to: 0
                    duration: 150
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: lyrics
                    property: "scale"
                    to: 0.95
                    duration: 150
                    easing.type: Easing.InQuad
                }
            }

            ScriptAction {
                script: lyrics.text = lyrics.pendingText
            }

            ParallelAnimation {
                NumberAnimation {
                    target: lyrics
                    property: "opacity"
                    to: 1
                    duration: 250
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: lyrics
                    property: "scale"
                    to: 1
                    duration: 350
                    easing.type: Easing.OutBack  // subtle overshoot/bounce
                }
            }
        }
    }
}
