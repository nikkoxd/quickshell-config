pragma ComponentBehavior: Bound

import QtQuick
import qs.Core

// A quick-settings tile. `wide` lays the label out beside the icon and is meant
// to span two grid columns; the square form stacks a small label under the
// icon. `active` paints the accent fill, so the same component covers both a
// toggle (which binds it to service state) and a plain shortcut (which never
// sets it).
//
// Like the other Core controls, a tile owns no state: it reports `clicked()`
// and the caller decides what that means.
Rectangle {
    id: root

    required property string icon
    // Swapped in while `active`, the way IconButton does it. Falls back to
    // `icon` so a tile that only changes colour needs nothing extra.
    property string activeIcon
    property string label
    // Second line on a wide tile, usually the toggle's state.
    property string sublabel
    property bool active: false
    property bool wide: false

    readonly property bool hovered: hover.hovered
    readonly property color contentColor: root.active ? Config.colorscheme.bg : Config.colorscheme.fg

    signal clicked

    radius: Config.island.radius * 0.75
    color: {
        if (root.active)
            return root.hovered ? Config.colorscheme.accentAlt : Config.colorscheme.accent;
        return root.hovered ? Config.colorscheme.dim : Config.colorscheme.surface;
    }

    Behavior on color {
        ColorAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        onTapped: root.clicked()
    }

    // Wide form: icon on the left, label (and state) beside it. Anchored rather
    // than laid out in a Row so the text column gets the exact leftover width
    // and elides against the tile's real edge.
    Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        visible: root.wide

        ThemedText {
            id: wideIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.active && root.activeIcon ? root.activeIcon : root.icon
            icon: true
            font.pixelSize: 20
            color: root.contentColor
        }

        Column {
            anchors.left: wideIcon.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            ThemedText {
                width: parent.width
                text: root.label
                color: root.contentColor
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                text: root.sublabel
                color: root.contentColor
                opacity: 0.7
                font.pixelSize: Config.theme.fontSize * 0.8
                elide: Text.ElideRight
                visible: root.sublabel !== ""
            }
        }
    }

    // Square form: icon over a small label.
    Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4
        visible: !root.wide

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.active && root.activeIcon ? root.activeIcon : root.icon
            icon: true
            font.pixelSize: 20
            color: root.contentColor
        }

        ThemedText {
            width: parent.width
            text: root.label
            color: root.contentColor
            opacity: 0.8
            font.pixelSize: Config.theme.fontSize * 0.75
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
