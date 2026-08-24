//@ pragma UseQApplication
//@ pragma IconTheme Reversal
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
import qs.Modules.Wallpapers as WallpapersModule
import qs.Modules.Lockscreen as LockscreenModule
import qs.Modules.Dock as DockModule

ShellRoot {
    WallpapersModule.Wallpaper {}
    ScreenCornersModule.ScreenCorners {}
    DockModule.Dock {}
    LockscreenModule.Lockscreen {}

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

        Component.onCompleted: {
            CliphistService.startListener();
        }

        anchors {
            top: true
            left: true
            right: true
        }

        HyprlandFocusGrab {
            id: grab
            windows: [root]
            // A view that closes when the pointer leaves must not steal the
            // keyboard just because the pointer drifted over it.
            active: bar.content.currentView.focused && !bar.hoverClosable
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
                shadowColor: "#af1a1a1a"
                shadowVerticalOffset: 10
                shadowHorizontalOffset: 0
                shadowScale: 0.9
                blurMax: 64
                blurMultiplier: 1.5
                shadowBlur: 1.0
                autoPaddingEnabled: true
            }

            Behavior on color {
                ColorAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
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
