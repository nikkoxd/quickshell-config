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
//
// `badge` is the small pill over the top-right corner - a count, a countdown,
// a plain "ON". It is empty by default and never affects the button's size, so
// a badge appearing does not reflow the row it sits in; it grows leftwards
// over the icon and only overhangs the corner slightly.
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
    // Empty hides it.
    property string badge: ""

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

    Rectangle {
        id: badgePill

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -3
        anchors.topMargin: -3

        // Rounded to whole pixels: a fractional pill leaves the centred label
        // on a half pixel, which snaps to the grid and reads as off-centre.
        implicitWidth: Math.max(badgePill.implicitHeight, Math.ceil(badgeLabel.implicitWidth) + 8)
        implicitHeight: Math.ceil(badgeLabel.implicitHeight) + 2
        radius: badgePill.height / 2
        // The accent is the button's own active fill, so a badge on an active
        // button borrows the foreground colour instead to stay readable.
        color: root.active ? Config.colorscheme.bg : Config.colorscheme.accent
        visible: root.badge !== ""

        FontMetrics {
            id: badgeMetrics
            font: badgeLabel.font
        }

        ThemedText {
            id: badgeLabel
            anchors.centerIn: parent
            // Centring the text box puts the digits high: the box reserves room
            // for descenders the badge never has. Nudge down by half of what
            // that costs, so the glyphs themselves sit in the middle.
            anchors.verticalCenterOffset: Math.round((badgeMetrics.descent - (badgeMetrics.ascent - badgeMetrics.capitalHeight)) / 2)
            text: root.badge
            color: root.active ? Config.colorscheme.fg : Config.colorscheme.bg
            font.pixelSize: Config.theme.fontSize * 0.7
        }
    }
}
