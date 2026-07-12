import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: row.implicitWidth + 20
    implicitHeight: row.implicitHeight + 20
    displayInFullscreen: true

    property Notification notification

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.LeftButton) {
                var defaultAction = root.notification.actions.find(a => a.identifier === "default");
                if (defaultAction) {
                    defaultAction.invoke();
                    root.closeRequested();
                }
            } else {
                root.viewChangeRequested("controlCenter");
            }
        }
    }

    Timer {
        id: timer
        interval: 5000
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

    Row {
        id: row
        spacing: 10
        anchors.centerIn: parent

        Image {
            source: Quickshell.iconPath(root.notification.appIcon, true)
            width: Math.min(row.implicitHeight, 42)
            height: Math.min(row.implicitHeight, 42)
            asynchronous: true
            visible: source.toString().length > 0
        }

        Column {
            spacing: 2

            ThemedText {
                id: title
                text: root.notification.appName + " - " + root.notification.summary
                font.pixelSize: 12
                opacity: 0.5
            }

            ThemedText {
                id: body
                text: root.notification.body
                width: 200
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }
}
