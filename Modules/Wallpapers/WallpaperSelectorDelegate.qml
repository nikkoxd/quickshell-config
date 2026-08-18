pragma ComponentBehavior: Bound
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.Core

Item {
    id: root
    property string preview: model.preview || ""
    required property var model
    required property int index
    signal clicked(int index)

    width: 220
    height: 140

    scale: PathView.iconScale || 0.6
    z: PathView.iconZ || 0

    readonly property string displaySource: root.preview || model.filePath
    readonly property bool isAnimated: displaySource.toLowerCase().endsWith(".gif")

    ClippingRectangle {
        id: clippingMask
        anchors.fill: parent
        border.width: 2
        border.color: Config.wallpaper.current === root.model.filePath ? Config.colorscheme.accent : hovered ? Config.colorscheme.accentAlt : "transparent"
        radius: 8
        color: Config.colorscheme.surface
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
                root.clicked(root.index);
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: root.isAnimated ? animatedComponent : staticComponent
        }

        Component {
            id: staticComponent
            Image {
                anchors.fill: parent
                source: root.displaySource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Component {
            id: animatedComponent
            AnimatedImage {
                anchors.fill: parent
                source: root.displaySource
                fillMode: Image.PreserveAspectCrop
                playing: true
            }
        }
    }
}
