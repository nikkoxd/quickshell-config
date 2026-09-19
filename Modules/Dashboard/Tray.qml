pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.Core

// The system tray, as a row of IconButtons matching the dashboard's own
// navigation. Tray items carry their own resolved icon path rather than a
// Phosphor ligature, so they go in through `iconSource`.
Row {
    id: root
    spacing: 8

    signal closeRequested

    property int size: 36
    property var popups: []

    Repeater {
        model: SystemTray.items

        IconButton {
            id: button
            required property SystemTrayItem modelData

            implicitWidth: root.size
            implicitHeight: root.size
            iconAsText: false
            iconSource: button.modelData.icon
            iconSize: 20

            QsMenuOpener {
                id: menuOpener
                menu: button.modelData.menu
            }

            onClicked: b => {
                if (b === Qt.RightButton) {
                    popupMenu.showMenu();
                    return;
                }
                button.modelData.activate();
                root.closeRequested();
            }

            PopupMenu {
                id: popupMenu
                anchor.item: button
                menu: menuOpener.children
                onCloseRequested: root.closeRequested()
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
