import QtQuick
import qs.Core

Item {
    id: root
    width: 24
    height: 24

    property alias text: icon.text
    signal clicked()

    Rectangle {
        id: background
        anchors.fill: parent
        color: Config.colorscheme.accent
        opacity: 0
        radius: 4

        Behavior on opacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
    }

    ThemedText {
        id: icon
        icon: true
        isHeading: true
        anchors.centerIn: parent

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered) {
                background.opacity = 1;
                icon.color = Config.colorscheme.bg;
            } else {
                background.opacity = 0;
                icon.color = Config.colorscheme.fg;
            }
        }
    }

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        onTapped: (event) => {
            root.clicked();
        }
    }
}
