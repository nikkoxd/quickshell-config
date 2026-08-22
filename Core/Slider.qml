import Quickshell
import Quickshell.Widgets
import QtQuick
// Qualified so `Slider` below is unambiguously the Controls one and not this
// file itself.
import QtQuick.Controls as Controls

Item {
    id: root
    implicitWidth: root.vertical ? 40 : 310
    implicitHeight: root.vertical ? 200 : 30

    property alias value: slider.value
    property string icon: ""
    property bool iconAsText: true
    property bool showIcon: root.icon !== ""
    property bool vertical: false

    // Track behind the fill. Transparent by default so the slider takes on
    // whatever it is placed over; the mixer draws its own background instead.
    property color trackColor: "transparent"
    property real radius: Config.island.radius / 2

    // Fill extent, in pixels, of the position the cursor is hovering over.
    // Bound to instead of assigned onto the preview rect so the rect keeps its
    // geometry bindings after the first hover.
    property real hoverPos: 0
    property bool hovering: false

    // Whether the fill has grown far enough to sit behind the icon glyph, so it
    // has to be drawn in the background color to stay readable.
    readonly property bool iconCovered: root.vertical ? slider.value * slider.height >= 30 : slider.value >= 0.07

    // Square the icon occupies: the full width when vertical, the full height
    // when horizontal.
    readonly property real iconSize: root.vertical ? root.width : root.height

    Controls.Slider {
        id: slider
        anchors.fill: parent
        orientation: root.vertical ? Qt.Vertical : Qt.Horizontal
        handle: Rectangle {}
        background: ClippingRectangle {
            clip: true
            radius: root.radius
            color: root.trackColor

            Rectangle {
                id: preview
                color: Config.colorscheme.fg
                width: root.vertical ? parent.width : root.hoverPos
                height: root.vertical ? root.hoverPos : parent.height
                y: root.vertical ? parent.height - height : 0
                radius: root.radius
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
                radius: root.radius

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

    // Both icon forms share one anchor block; only one of them is ever visible.
    Item {
        visible: root.showIcon
        width: root.iconAsText ? label.width : root.iconSize
        height: root.iconAsText ? label.height : root.iconSize
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.left: root.vertical ? undefined : parent.left
        anchors.leftMargin: 10
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.bottomMargin: 10

        IconImage {
            anchors.fill: parent
            source: Quickshell.iconPath(root.icon, true)
            visible: !root.iconAsText
        }

        ThemedText {
            id: label
            text: root.icon
            icon: true
            color: root.iconCovered ? Config.colorscheme.bg : Config.colorscheme.fg
            visible: root.iconAsText

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
