pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects
import qs.Core

Column {
    id: root
    spacing: 5

    signal closeRequested

    property var popups: []

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem
            implicitWidth: 24
            implicitHeight: 24
            required property SystemTrayItem modelData

            QsMenuOpener {
                id: menuOpener
                menu: trayItem.modelData.menu
            }

            Rectangle {
                id: background
                anchors.fill: parent
                opacity: 0
                radius: 4
                color: Config.colorscheme.accent

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            IconImage {
                id: icon
                anchors.fill: parent
                source: trayItem.modelData.icon
                anchors.margins: 4
                visible: false
            }

            MultiEffect {
                id: effect
                source: icon
                anchors.fill: icon
                colorization: 0
                colorizationColor: Config.colorscheme.bg

                Behavior on colorization {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    if (hovered) {
                        effect.colorization = 1;
                        background.opacity = 1;
                    } else {
                        effect.colorization = 0;
                        background.opacity = 0;
                    }
                }
            }

            TapHandler {
                gesturePolicy: TapHandler.WithinBounds
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: (eventPoint, button) => {
                    if (button === Qt.LeftButton) {
                        trayItem.modelData.activate();
                        root.closeRequested();
                    } else if (button === Qt.RightButton) {
                        popupMenu.showMenu();
                    }
                }
            }

            PopupMenu {
                id: popupMenu
                anchor.item: trayItem
                menu: menuOpener.children
                onCloseRequested: {
                    root.closeRequested();
                }
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
