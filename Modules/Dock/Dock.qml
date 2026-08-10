pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.Core

PanelWindow {
    id: root
    color: "transparent"
    implicitWidth: Screen.width
    implicitHeight: Screen.height

    // Only the dock itself and the hover hotzone take input; the rest of the
    // fullscreen surface stays click-through.
    mask: Region {
        Region {
            item: dock
        }
        Region {
            item: hotzone
        }
    }
    exclusionMode: ExclusionMode.Ignore

    anchors.bottom: true

    readonly property bool revealed: !Config.dock.onlyOnHover || dockHover.hovered || hotzoneHover.hovered

    Item {
        id: hotzone
        width: Screen.width
        height: Config.dock.onlyOnHover ? Config.dock.hotzoneHeight : 0
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        HoverHandler {
            id: hotzoneHover
        }
    }


    Item {
        id: dock
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: root.revealed ? Config.island.margins : -height

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: dockHover
        }

        Rectangle {
            id: background
            anchors.fill: parent
            radius: Config.island.radius
            color: Config.colorscheme.bg
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
        }

        Row {
            id: content
            spacing: Config.dock.spacing
            anchors.centerIn: parent
            padding: Config.island.margins
            leftPadding: Config.island.margins * 2
            rightPadding: Config.island.margins * 2

            Repeater {
                model: ToplevelManager.toplevels

                DockEntry {
                    required property Toplevel modelData
                    toplevel: modelData
                    size: Config.dock.iconSize
                }
            }
        }
    }
}
