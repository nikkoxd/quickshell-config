import QtQuick
import QtQuick.Layouts
import qs.Core

Rectangle {
    id: root
    height: 40
    color: getColor()
    radius: Config.island.radius / 2
    Layout.fillWidth: true

    required property string icon
    property bool active: false
    property string activeIcon
    property bool hovered: false

    signal clicked(button: int)

    function getColor() {
        if (active && hovered) {
            return Config.colorscheme.accentAlt
        } else if (active) {
            return Config.colorscheme.accent
        } else if (hovered) {
            return Config.colorscheme.dim
        } else {
            return Config.colorscheme.surface
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (point, button) => {
            root.clicked(button);
        }
    }

    ThemedText {
        text: root.active && root.activeIcon ? root.activeIcon : root.icon
        icon: true
        color: root.active ? Config.colorscheme.bg : Config.colorscheme.fg
        font.pixelSize: 16
        anchors.centerIn: parent
    }
}
