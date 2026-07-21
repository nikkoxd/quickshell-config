import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: text.implicitWidth + Config.island.padding * 2
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

    ThemedText {
        id: text
        text: DateService.hours + ":" + DateService.minutes
        anchors.centerIn: parent
    }
}
