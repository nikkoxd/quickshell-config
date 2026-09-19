import Quickshell
import Quickshell.Widgets
import QtQuick

// Square icon button that can also read as a toggle: `active` swaps in
// `activeIcon` and the accent background.
//
// `icon` is a Phosphor ligature by default; `iconAsText: false` draws a themed
// app icon instead, resolved from `icon` through the icon theme or taken
// verbatim from `iconSource` when something already has a path (a tray item,
// say). Same knob as Slider, so both read the same way at the call site.
Rectangle {
    id: root
    implicitWidth: 30
    implicitHeight: 30
    color: getColor()
    radius: Config.island.radius / 2

    property string icon: ""
    property bool iconAsText: true
    property string iconSource: ""
    property int iconSize: 18
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

    // Only one of the two is ever visible.
    IconImage {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.iconSource !== "" ? root.iconSource : Quickshell.iconPath(root.icon, true)
        visible: !root.iconAsText
    }

    ThemedText {
        text: root.active && root.activeIcon ? root.activeIcon : root.icon
        icon: true
        color: root.active ? Config.colorscheme.bg : Config.colorscheme.fg
        font.pixelSize: 16
        anchors.centerIn: parent
        visible: root.iconAsText
    }
}
