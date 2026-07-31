pragma ComponentBehavior: Bound

import QtQuick
import qs.Core

Rectangle {
    id: root
    height: 40
    width: 40
    radius: Config.island.radius / 2
    color: focused ? Config.colorscheme.accent : hovered ? Config.colorscheme.surface : Config.colorscheme.bg
    property bool focused: false
    property bool hovered: false
    required property string icon
    property Component iconComponent: ThemedText {
        text: root.icon
        icon: true
        font.pixelSize: 18
        color: root.focused ? Config.colorscheme.bg : Config.colorscheme.fg
    }
    signal clicked()

    Behavior on color {
        ColorAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: root.hovered = hovered
    }

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        onTapped: (event) => {
            root.clicked();
        }
    }

    Loader {
        anchors.centerIn: parent
        sourceComponent: root.iconComponent
    }
}
