//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Services
import qs.Modules.ScreenCorners as ScreenCornersModule

ShellRoot {
    ScreenCornersModule.ScreenCorners {}

    PanelWindow {
        id: root
        color: "transparent"
        implicitWidth: Screen.width
        implicitHeight: Screen.height
        exclusiveZone: Config.island.height + Config.island.margins
        mask: Region {
            item: background
        }
        WlrLayershell.layer: bar.content.currentView.displayInFullscreen ? WlrLayer.Overlay : WlrLayer.Top

        anchors {
            top: true
            left: true
            right: true
        }

        HyprlandFocusGrab {
            id: grab
            windows: [root]
            active: bar.content.currentView.focused
            onCleared: {
                if (bar.content.currentView.popups.length === 0) {
                    LocalSendService.rejectTransfer();
                    bar.openDefaultView();
                }
            }
        }

        Rectangle {
            id: background
            color: Config.colorscheme.bg
            height: content.height
            width: content.width
            radius: Config.island.radius
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Config.island.margins
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.5
            }
        }

        Item {
            id: content
            width: childrenRect.width
            height: childrenRect.height
            anchors.top: parent.top
            anchors.topMargin: Config.island.margins
            anchors.horizontalCenter: parent.horizontalCenter

            Bar {
                id: bar
            }
        }
    }
}
