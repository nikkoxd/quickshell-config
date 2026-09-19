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
    readonly property bool hovered: hover.hovered
    // True while *any* entry in the dock is being dragged, so a passive hover
    // picked up under the dragged icon doesn't light this one up too.
    property bool dockDragging: false
    // How many slots this entry is displaced by to make room for the icon being
    // dragged. The model is only reordered on drop, so this is the whole of the
    // reorder preview.
    property int shiftSlots: 0
    readonly property real slotStep: size + Config.dock.spacing
    // Position of the icon inside the dock row, shift and drag offset included.
    readonly property real centerX: x + slot.x + content.x + width / 2

    signal dragStarted
    signal dragMoved(real centerX)
    signal dragFinished
    signal menuRequested(Item anchor, var item)

    implicitWidth: size
    implicitHeight: size + 6

    // Two layers, because the two offsets want opposite treatment: the reorder
    // shift slides, the drag offset has to track the cursor exactly and snap
    // back on drop.
    Item {
        id: slot
        width: root.width
        height: root.height
        z: dragHandler.active ? 10 : 0
        x: root.shiftSlots * root.slotStep

        Behavior on x {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: content
            width: root.width
            height: root.height
            x: dragHandler.active ? dragHandler.activeTranslation.x : 0

            onXChanged: {
                if (dragHandler.active)
                    root.dragMoved(root.centerX);
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            DragHandler {
                id: dragHandler
                // No target: content.x is bound to activeTranslation above, so
                // the binding stays intact and nothing has to fight the
                // handler's own writes.
                target: null
                yAxis.enabled: false

                onActiveChanged: {
                    if (active)
                        root.dragStarted();
                    else
                        root.dragFinished();
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
                scale: (hover.hovered && !root.dockDragging) || dragHandler.active ? 1.15 : 1.0
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
}
