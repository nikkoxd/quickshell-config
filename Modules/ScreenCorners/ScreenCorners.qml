import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {
        item: null
    }
    visible: !Hyprland.activeToplevel.wayland.fullscreen
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Item {
        id: container
        anchors.fill: parent

        ScreenCorner {
            anchors.left: container.left
            anchors.top: container.top
            corner: ScreenCorner.CornerEnum.TopLeft
        }

        ScreenCorner {
            anchors.right: container.right
            anchors.top: container.top
            corner: ScreenCorner.CornerEnum.TopRight
        }

        ScreenCorner {
            anchors.left: container.left
            anchors.bottom: container.bottom
            corner: ScreenCorner.CornerEnum.BottomLeft
        }

        ScreenCorner {
            anchors.right: container.right
            anchors.bottom: container.bottom
            corner: ScreenCorner.CornerEnum.BottomRight
        }
    }
}
