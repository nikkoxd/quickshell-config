import QtQuick
import qs.Core

Rectangle {
    id: root
    color: selected ? Config.colorscheme.accent : hoverHandler.hovered ? Config.colorscheme.surface : Config.colorscheme.bg
    width: 250
    height: 40
    radius: 10

    signal tapped()
    required property string text
    required property string icon
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

    Row {
        x: 15
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        ThemedText {
            color: root.selected ? Config.colorscheme.bg : Config.colorscheme.fg
            text: root.icon
            icon: true
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ThemedText {
            color: root.selected ? Config.colorscheme.bg : Config.colorscheme.fg
            text: root.text
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
