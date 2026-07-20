import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

Column {
    spacing: 5
    visible: NotificationService.server.trackedNotifications.values.length > 0

    ListView {
        id: list
        clip: true
        width: 310
        height: Math.min(contentHeight, 200)
        spacing: 5
        model: NotificationService.server.trackedNotifications
        verticalLayoutDirection: ListView.BottomToTop
        onCountChanged: {
            Qt.callLater(function () {
                list.positionViewAtEnd();
            });
        }
        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                property: "scale"
                from: 0.9
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        delegate: ControlCenterNotification {}
    }
}
