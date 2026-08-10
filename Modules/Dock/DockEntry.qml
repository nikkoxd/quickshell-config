pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Services

Item {
    id: root

    // One entry per application, as built by DockService:
    // { appId, entry, toplevels, pinned }.
    required property var modelData
    required property int index
    property int size: 40

    readonly property var toplevels: modelData.toplevels ?? []
    readonly property bool running: toplevels.length > 0
    readonly property bool activated: toplevels.some(toplevel => toplevel.activated)
    readonly property bool dragging: dragHandler.active
    // Position of the icon inside the dock row, drag offset included.
    readonly property real centerX: x + content.x + width / 2

    signal dragMoved(real centerX)
    signal dragFinished
    signal menuRequested(Item anchor, var item)

    implicitWidth: size
    implicitHeight: size + 6

    // The Row owns root.x. When a drag causes a reorder our slot moves, so
    // cancel the shift out of the drag offset to keep the icon under the cursor.
    property real layoutX: x
    onXChanged: {
        if (dragHandler.active)
            content.x -= x - layoutX;
        layoutX = x;
    }

    Item {
        id: content
        width: root.width
        height: root.height
        z: dragHandler.active ? 10 : 0

        onXChanged: {
            if (dragHandler.active)
                root.dragMoved(root.centerX);
        }

        Behavior on x {
            enabled: !dragHandler.active

            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }

        DragHandler {
            id: dragHandler
            target: content
            yAxis.enabled: false

            onActiveChanged: {
                if (active) {
                    root.layoutX = root.x;
                } else {
                    content.x = 0;
                    root.dragFinished();
                }
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onTapped: (eventPoint, button) => {
                if (button === Qt.MiddleButton)
                    DockService.launch(root.modelData);
                else if (button === Qt.RightButton)
                    root.menuRequested(root, root.modelData);
                else
                    DockService.activate(root.modelData);
            }
        }

        IconImage {
            id: icon
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: root.size
            asynchronous: true
            source: {
                const name = root.modelData.entry ? root.modelData.entry.icon : root.modelData.appId;
                return Quickshell.iconPath(name, "application-x-executable");
            }
            scale: hover.hovered || dragHandler.active ? 1.15 : 1.0
            opacity: root.running ? 1.0 : 0.75
            layer.enabled: Config.dock.coloredIcons
            layer.effect: MultiEffect {
                colorization: 0.5
                colorizationColor: Config.colorscheme.accent
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        // running / focused indicator; pinned apps with no window show none
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.activated ? 12 : 4
            height: 4
            radius: 2
            color: root.activated ? Config.colorscheme.accent : Config.colorscheme.fg
            opacity: !root.running ? 0 : root.activated ? 1.0 : 0.4

            Behavior on width {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
