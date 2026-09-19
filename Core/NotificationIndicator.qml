import QtQuick
import qs.Services

// The unread-notification indicator shown in the default views: a bell plus the
// number of tracked notifications. Muting swaps the glyph rather than hiding
// the indicator, so a silenced shell still says so at a glance.
Row {
    id: root
    spacing: 3

    readonly property int count: NotificationService.notifications.length

    visible: root.count > 0 || NotificationService.muted
    opacity: NotificationService.muted ? 0.5 : 1

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    ThemedText {
        text: NotificationService.muted ? "bell-slash" : "bell"
        icon: true
        font.pixelSize: 13
        anchors.verticalCenter: parent.verticalCenter
    }

    ThemedText {
        text: root.count
        font.pixelSize: 12
        visible: root.count > 0
        anchors.verticalCenter: parent.verticalCenter
    }
}
