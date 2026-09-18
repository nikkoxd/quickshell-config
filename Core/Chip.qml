import QtQuick

// A labelled toggle pill. Unlike SegmentPill, chips are independent of each
// other, so a set of them reads as a multi-select filter. Like the other
// controls it only reports the click — the caller owns `active`.
Rectangle {
    id: root

    property string text
    property bool active: false
    property bool icon: false
    property int horizontalPadding: 14
    property int verticalPadding: 6
    property bool hovered: false

    signal clicked

    implicitWidth: label.implicitWidth + root.horizontalPadding * 2
    implicitHeight: label.implicitHeight + root.verticalPadding * 2
    radius: height / 2
    color: {
        if (root.active && root.hovered)
            return Config.colorscheme.accentAlt;
        if (root.active)
            return Config.colorscheme.accent;
        if (root.hovered)
            return Config.colorscheme.dim;
        return Config.colorscheme.surface;
    }

    Behavior on color {
        ColorAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: root.hovered = hovered
    }

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        onTapped: root.clicked()
    }

    ThemedText {
        id: label
        anchors.centerIn: parent
        icon: root.icon
        text: root.text
        color: root.active ? Config.colorscheme.bg : Config.colorscheme.fg

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
    }
}
