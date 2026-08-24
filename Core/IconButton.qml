import QtQuick

// Square icon button that can also read as a toggle: `active` swaps in
// `activeIcon` and the accent background.
Rectangle {
    id: root
    implicitWidth: 30
    implicitHeight: 30
    color: getColor()
    radius: Config.island.radius / 2

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
