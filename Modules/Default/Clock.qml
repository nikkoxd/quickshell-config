import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding * 2
    implicitHeight: Config.island.height

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
            root.defaultViewChangeRequested("lyrics");
            root.viewChangeRequested("lyrics");
        }
    }

    Row {
        id: row
        spacing: 6
        anchors.centerIn: parent

        Rectangle {
            id: dot
            width: 8
            height: 8
            radius: width / 2
            color: "#ff5555"
            visible: RecordingService.recording
            anchors.verticalCenter: parent.verticalCenter

            SequentialAnimation on opacity {
                running: dot.visible
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1
                    to: 0.2
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    from: 0.2
                    to: 1
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ThemedText {
            id: text
            text: DateService.hours + ":" + DateService.minutes
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
