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
import qs.Modules.Widgets as WidgetsModule

ShellRoot {
    WallpapersModule.Wallpaper {}
    ScreenCornersModule.ScreenCorners {}
    DockModule.Dock {}
    WidgetsModule.Widgets {}
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
            // A view swapped in by hover must not steal the keyboard just
            // because the pointer drifted over the island. One opened
            // deliberately grabs even if it also closes on unhover.
            active: bar.content.currentView.focused && !bar.hoverOpened
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
            // A view laid out asymmetrically asks the island to slide, so the
            // part of it that should read as centred ends up over the middle
            // of the screen rather than the island's own middle.
            anchors.horizontalCenterOffset: bar.content.currentView.centreOffset
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

            // Matches the island's resize, so a flank filling up slides and
            // grows in one motion.
            Behavior on anchors.horizontalCenterOffset {
                NumberAnimation {
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
            anchors.horizontalCenterOffset: bar.content.currentView.centreOffset

            Behavior on anchors.horizontalCenterOffset {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Bar {
                id: bar
            }
        }
    }
}
