import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

Column {
    spacing: 5
    visible: NotificationService.server.trackedNotifications.values.length > 0

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        ThemedText {
            text: "Notifications"
            opacity: 0.6
            font.pixelSize: Config.theme.fontSize * 1.15
        }

        ThemedText {
            text: "Clear all"
            opacity: 0.6
            font.pixelSize: Config.theme.fontSize * 0.9
            Layout.alignment: Qt.AlignRight

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    if (hovered) {
                        parent.opacity = 1;
                    } else {
                        parent.opacity = 0.6;
                    }
                }
            }

            TapHandler {
                gesturePolicy: TapHandler.WithinBounds
                onTapped: {
                    const notifs = [...NotificationService.server.trackedNotifications.values];
                    for (let i = 0; i < notifs.length; i++) {
                        notifs[i].dismiss();
                    }
                }
            }
        }
    }

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
