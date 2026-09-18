pragma ComponentBehavior: Bound
import Quickshell.Widgets
import QtQuick
import qs.Core

// One search result: its thumbnail, with the resolution pinned in a corner and
// a spinner over it while that wallpaper is being fetched.
Item {
    id: root

    // Filled from the model's roles by the view.
    required property string thumb
    required property string resolution

    property bool downloading: false
    property bool downloaded: false
    property bool current: false

    signal clicked

    ClippingRectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 6
        radius: 8
        color: Config.colorscheme.surface
        border.width: 2
        border.color: root.current ? Config.colorscheme.accent : hovered ? Config.colorscheme.accentAlt : "transparent"

        property bool hovered: false

        Behavior on border.color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: card.hovered = hovered
        }

        TapHandler {
            gesturePolicy: TapHandler.WithinBounds
            onTapped: root.clicked()
        }

        Image {
            id: thumbnail
            anchors.fill: parent
            source: root.thumb
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        // Thumbnails come off the network, so a slot can sit empty for a while.
        ThemedText {
            anchors.centerIn: parent
            visible: thumbnail.status !== Image.Ready
            icon: true
            text: thumbnail.status === Image.Error ? "warning" : "image"
            color: Qt.alpha(Config.colorscheme.fg, 0.4)
            font.pixelSize: 24
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 6
            width: badge.implicitWidth + 12
            height: badge.implicitHeight + 6
            radius: height / 2
            color: Qt.alpha(Config.colorscheme.bg, 0.75)
            visible: thumbnail.status === Image.Ready

            Row {
                id: badge
                anchors.centerIn: parent
                spacing: 4

                // Already sitting in the local folder — clicking it only
                // reapplies it, nothing is fetched again.
                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.downloaded
                    icon: true
                    text: "check-circle"
                    color: Config.colorscheme.accent
                    font.pixelSize: Config.theme.fontSize * 0.9
                }

                ThemedText {
                    id: resolution
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.resolution
                    font.pixelSize: Config.theme.fontSize * 0.8
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.downloading
            color: Qt.alpha(Config.colorscheme.bg, 0.6)

            ThemedText {
                anchors.centerIn: parent
                icon: true
                text: "circle-notch"
                font.pixelSize: 24

                RotationAnimation on rotation {
                    running: root.downloading
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }
        }
    }
}
