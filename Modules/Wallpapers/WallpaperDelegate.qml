import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.Core

Item {
    id: root
    required property string filePath
    signal clicked(string wallpaper)

    width: 220
    height: 140

    scale: PathView.iconScale || 0.6
    z: PathView.iconZ || 0

    ClippingRectangle {
        id: clippingMask
        anchors.fill: parent
        border.width: 2
        border.color: Config.theme.wallpaper === root.filePath ? Config.colorscheme.accent : hovered ? Config.colorscheme.accentAlt : "transparent"
        radius: 8
        color: Config.colorscheme.bgAlt
        property bool hovered: false
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Config.colorscheme.bg
            shadowScale: 1.05
            shadowOpacity: 0.4
            shadowBlur: 1
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: clippingMask.hovered = hovered
        }

        TapHandler {
            gesturePolicy: TapHandler.WithinBounds
            onTapped: {
                // PathView.view.currentIndex = index;
                root.clicked(root.filePath);
            }
        }

        Image {
            anchors.fill: parent
            source: root.filePath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
}
