import QtQuick
import qs.Core

Rectangle {
    id: root
    height: 50
    width: wide ? 310 : 150
    color: getColor()
    radius: Config.island.radius / 2

    property bool active: false
    property bool wide: false
    property bool hovered: false
    required property string text
    required property string icon
    required property string status

    signal clicked
    signal iconClicked

    function getColor() {
        if (hovered) {
            return active ? ThemeLoader.adapter.bg3 : ThemeLoader.adapter.bg2;
        } else {
            return active ? ThemeLoader.adapter.bg2 : ThemeLoader.adapter.bg;
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered) {
                root.hovered = true;
            } else {
                root.hovered = false;
            }
        }
    }

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        onTapped: {
            root.clicked();
        }
    }

    Row {
        spacing: 10
        anchors.fill: parent
        anchors.margins: 10

        Item {
            width: parent.height
            height: parent.height

            TapHandler {
                gesturePolicy: TapHandler.WithinBounds
                onTapped: {
                    root.iconClicked();
                }
            }

            Rectangle {
                id: iconBackground
                anchors.fill: parent
                color: Config.colorscheme.fg
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.2
            }

            ThemedText {
                text: root.icon
                icon: true
                color: Config.colorscheme.fg
                anchors.centerIn: iconBackground
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            ThemedText {
                text: root.text
            }

            ThemedText {
                text: root.status
                font.pixelSize: Config.theme.fontSize * 0.8
                opacity: 0.5
            }
        }
    }
}
