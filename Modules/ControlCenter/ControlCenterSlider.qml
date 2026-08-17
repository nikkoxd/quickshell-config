import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.Core

Item {
    id: root
    implicitWidth: root.vertical ? 40 : 310
    implicitHeight: root.vertical ? 200 : 30

    property alias value: slider.value
    required property string icon
    property bool iconAsText: true
    property bool vertical: false

    // Fill extent, in pixels, of the position the cursor is hovering over.
    // Bound to instead of assigned onto the preview rect so the rect keeps its
    // geometry bindings after the first hover.
    property real hoverPos: 0
    property bool hovering: false

    // Whether the fill has grown far enough to sit behind the icon glyph, so it
    // has to be drawn in the background color to stay readable.
    readonly property bool iconCovered: root.vertical ? slider.value * slider.height >= 30 : slider.value >= 0.07

    Slider {
        id: slider
        anchors.fill: parent
        orientation: root.vertical ? Qt.Vertical : Qt.Horizontal
        handle: Rectangle {}
        background: ClippingRectangle {
            clip: true
            radius: Config.island.radius / 2
            color: "transparent"

            Rectangle {
                id: preview
                color: Config.colorscheme.fg
                width: root.vertical ? parent.width : root.hoverPos
                height: root.vertical ? root.hoverPos : parent.height
                y: root.vertical ? parent.height - height : 0
                radius: Config.island.radius / 2
                opacity: root.hovering ? 0.2 : 0

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Rectangle {
                id: fill
                color: Config.colorscheme.accent
                width: root.vertical ? parent.width : parent.width * slider.value
                height: root.vertical ? parent.height * slider.value : parent.height
                y: root.vertical ? parent.height - height : 0
                radius: Config.island.radius / 2

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                root.hovering = hovered;
            }
            onPointChanged: {
                root.hoverPos = root.vertical ? slider.height - point.position.y : point.position.x;
            }
        }
    }

    IconImage {
        source: Quickshell.iconPath(root.icon, true)
        height: root.vertical ? parent.width : parent.height
        width: root.vertical ? parent.width : parent.height
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.left: root.vertical ? undefined : parent.left
        anchors.leftMargin: 10
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.bottomMargin: 10
        visible: !root.iconAsText
    }

    ThemedText {
        text: root.icon
        icon: true
        color: root.iconCovered ? Config.colorscheme.bg : Config.colorscheme.fg
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.left: root.vertical ? undefined : parent.left
        anchors.leftMargin: 10
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.bottomMargin: 10
        visible: root.iconAsText

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
    }
}
