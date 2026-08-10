import QtQuick
import qs.Core

View {
    id: root
    implicitWidth: column.implicitWidth + 30
    implicitHeight: column.implicitHeight + 30
    focused: true
    dismissable: false
    displayInFullscreen: true

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.LeftButton) {
                root.viewChangeRequested("dashboard");
            } else {
                root.closeRequested();
            }
        }
    }

    Column {
        id: column
        spacing: 15
        x: 15
        y: 15

        ControlCenterSettings {
            onViewChangeRequested: (view) => root.viewChangeRequested(view);
        }
        ControlCenterVolume {}
        ControlCenterNotifications {}
    }
}
