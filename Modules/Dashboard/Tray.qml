pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects
import qs.Core

// The system tray as a single pill: the items are one group rather than a row
// of separate buttons, so they read as one control beside the dashboard's own
// square buttons instead of competing with them. Tray icons carry a resolved
// path rather than a Phosphor ligature, so they are drawn as images.
//
// The pill takes whatever width the footer leaves it and centres the icons in
// it, so the right edge lines up with the tiles above however many items the
// tray happens to hold.
Rectangle {
    id: root

    signal closeRequested

    // Height of the pill. The width is the caller's to give - the icons centre
    // in whatever it ends up being.
    property int size: 36
    property int iconSize: 18
    property int spacing: 10
    property var popups: []

    readonly property int count: SystemTray.items.values.length

    implicitHeight: root.size
    // Only the floor, for a caller that does not stretch it.
    implicitWidth: row.implicitWidth + root.size / 2
    // Same corner as the buttons it shares the footer with.
    radius: Config.island.radius / 2
    color: Config.colorscheme.surface
    // Nothing to group when the tray is empty, and an empty pill still holds
    // its width open in the row.
    visible: root.count > 0

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing

        Repeater {
            model: SystemTray.items

            Item {
                id: item
                required property SystemTrayItem modelData

                implicitWidth: root.iconSize
                implicitHeight: root.iconSize
                // The pill is the background, so an item only marks itself on
                // hover rather than carrying a fill of its own.
                opacity: hover.hovered ? 1 : 0.75

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                IconImage {
                    anchors.fill: parent
                    source: item.modelData.icon
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: Config.colorscheme.fg
                    }
                }

                QsMenuOpener {
                    id: menuOpener
                    menu: item.modelData.menu
                }

                TapHandler {
                    gesturePolicy: TapHandler.WithinBounds
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onTapped: (point, button) => {
                        if (button === Qt.RightButton) {
                            popupMenu.showMenu();
                            return;
                        }
                        item.modelData.activate();
                        root.closeRequested();
                    }
                }

                PopupMenu {
                    id: popupMenu
                    anchor.item: item
                    menu: menuOpener.children
                    onCloseRequested: root.closeRequested()
                    // The island reads as unhovered while a menu window is up,
                    // so the view has to know one is open to stay put.
                    onVisibleChanged: {
                        if (visible) {
                            root.popups = [...root.popups, popupMenu];
                        } else {
                            root.popups = root.popups.filter(w => w !== popupMenu);
                        }
                    }
                }
            }
        }
    }
}
