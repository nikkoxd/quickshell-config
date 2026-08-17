import QtQuick
import qs.Core

View {
    id: root
    implicitWidth: column.implicitWidth + Config.island.padding
    implicitHeight: column.implicitHeight + Config.island.padding
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
        spacing: Config.island.padding / 2
        x: Config.island.padding / 2
        y: Config.island.padding / 2

        ControlCenterSettings {
            onViewChangeRequested: (view) => root.viewChangeRequested(view);
        }
        ControlCenterVolume {}
        ControlCenterNotifications {}
    }
}
