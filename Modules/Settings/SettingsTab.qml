import QtQuick
import qs.Core

Rectangle {
    id: root
    color: selected ? Config.colorscheme.accent : hoverHandler.hovered ? Config.colorscheme.bgAlt : Config.colorscheme.bg
    width: 250
    height: 40
    radius: 10

    signal tapped()
    required property string text
    property bool selected: false

    Behavior on color {
        ColorAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.tapped();
    }

    ThemedText {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        color: selected ? Config.colorscheme.bg : Config.colorscheme.fg
        text: root.text
        font.pixelSize: 16

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
    }
}
