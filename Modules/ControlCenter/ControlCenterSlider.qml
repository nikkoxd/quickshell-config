import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.Core

Item {
    id: root
    implicitWidth: 310
    implicitHeight: 30

    property alias value: slider.value
    required property string icon
    property bool iconAsText: true

    Slider {
        id: slider
        anchors.fill: parent
        handle: Rectangle {}
        background: ClippingRectangle {
            clip: true
            radius: Config.island.radius / 2
            color: "transparent"

            Rectangle {
                id: previewBottom
                color: Config.colorscheme.fg
                height: parent.height
                width: parent.width * slider.value
                radius: Config.island.radius / 2
                opacity: 0

                Behavior on width {
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
                id: background
                color: Config.colorscheme.accent
                height: parent.height
                width: parent.width * slider.value
                radius: Config.island.radius / 2

                Behavior on width {
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
                if (hovered) {
                    previewBottom.opacity = 0.2;
                } else {
                    previewBottom.opacity = 0;
                }
            }
            onPointChanged: {
                previewBottom.width = point.position.x;
            }
        }
    }

    IconImage {
        source: Quickshell.iconPath(root.icon, true)
        height: parent.height
        width: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        visible: !root.iconAsText
    }

    ThemedText {
        text: root.icon
        icon: true
        color: slider.value >= 0.07 ? Config.colorscheme.bg : Config.colorscheme.fg
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        visible: root.iconAsText

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
    }
}
