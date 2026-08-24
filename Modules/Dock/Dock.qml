pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Services

LazyLoader {
    active: Config.dock.enabled

    PanelWindow {
        id: root
        color: "transparent"
        implicitWidth: Screen.width
        implicitHeight: Screen.height

        // Only the dock itself and the hover hotzone take input; the rest of the
        // fullscreen surface stays click-through. While a context menu is open the
        // catcher covers the screen so a click anywhere dismisses it.
        mask: Region {
            Region {
                item: dock
            }
            Region {
                item: hotzone
            }
            Region {
                item: catcher
            }
        }
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Config.dock.onlyOnHover ? 0 : dock.implicitHeight + Config.island.margins

        anchors.bottom: true

        readonly property bool revealed: !Config.dock.onlyOnHover || workspaceClear || dockHover.hovered || hotzoneHover.hovered || menu.visible || dragging
        property bool dragging: false

        // Nothing on the workspace claims the bottom of the screen: either no
        // windows at all, or only floating ones. `floating` isn't a property of
        // HyprlandToplevel, it only lives in the `clients` IPC payload.
        // Only a window known to be tiled hides the dock: a toplevel Hyprland
        // hasn't described yet has an empty lastIpcObject, and treating that as
        // tiled made every newly opened window — floating ones included — hide
        // the dock until something else refreshed it.
        readonly property bool workspaceClear: (Hyprland.focusedWorkspace?.toplevels.values ?? []).every(toplevel => toplevel.lastIpcObject.floating !== false)

        Connections {
            target: Hyprland

            function onRawEvent(event) {
                // `openwindow` beats the `clients` dump the new window has to
                // come from, and toggling float state doesn't invalidate
                // lastIpcObject at all, so refresh on both.
                if (event.name === "openwindow" || event.name === "changefloatingmode")
                    Hyprland.refreshToplevels();
            }
        }

        // Entry the tooltip describes, or null when nothing is hovered.
        property DockEntry hoveredEntry: null

        onDraggingChanged: {
            if (dragging)
                root.hoveredEntry = null;
        }

        onHoveredEntryChanged: {
            if (root.hoveredEntry) {
                tooltipDelay.restart();
            } else {
                tooltipDelay.stop();
                tooltip.visible = false;
            }
        }

        Timer {
            id: tooltipDelay
            interval: 350
            onTriggered: tooltip.visible = root.hoveredEntry !== null && !menu.visible
        }

        // Index the dragged icon should land on, from its centre in row coordinates.
        // Every entry has the same width, so this is plain arithmetic.
        function indexAt(centerX) {
            const step = Config.dock.iconSize + Config.dock.spacing;
            const first = content.leftPadding + Config.dock.iconSize / 2;
            const last = DockService.items.length - 1;
            return Math.max(0, Math.min(last, Math.round((centerX - first) / step)));
        }

        Item {
            id: hotzone
            width: dock.width
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
                    // ScriptModel diffs the array into insert/remove/move
                    // operations, so reordering keeps the delegates alive and a
                    // drag survives the item it is dragging changing places.
                    model: ScriptModel {
                        values: DockService.items
                        objectProp: "appId"
                    }

                    DockEntry {
                        id: entry
                        size: Config.dock.iconSize

                        onDraggingChanged: root.dragging = entry.dragging

                        onHoveredChanged: {
                            if (entry.hovered)
                                root.hoveredEntry = entry;
                            else if (root.hoveredEntry === entry)
                                root.hoveredEntry = null;
                        }

                        onDragMoved: centerX => DockService.move(entry.index, root.indexAt(centerX))

                        onDragFinished: DockService.persistOrder()

                        onMenuRequested: (anchor, item) => root.openMenu(anchor, item)
                    }
                }
            }
        }

        function openMenu(anchor, item) {
            // Actions look the app up again when they run: the menu outlives the
            // item object, which is rebuilt whenever a window opens or closes.
            const appId = item.appId;
            const pinned = DockService.isPinned(appId);
            const entries = [
                      {
                          text: pinned ? "Unpin" : "Pin",
                          icon: pinned ? "push-pin-slash" : "push-pin",
                          triggered: () => {
                              DockService.togglePin(appId);
                          }
                      }
                  ];

            if (item.toplevels.length > 0)
                entries.push({
                                 text: item.toplevels.length > 1 ? "Close all windows" : "Close",
                                 icon: "x-circle",
                                 triggered: () => {
                                     DockService.close(DockService.itemFor(appId));
                                 }
                             });

            const pos = anchor.mapToItem(root.contentItem, anchor.width / 2, 0);
            menu.anchorCenterX = pos.x;
            menu.anchorTopY = pos.y;
            menu.open(entries);

            tooltipDelay.stop();
            tooltip.visible = false;
        }

        // Full-screen click target that dismisses the menu; zero-sized (and so
        // absent from the input mask) while no menu is open.
        Item {
            id: catcher
            width: menu.visible ? root.width : 0
            height: menu.visible ? root.height : 0

            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onTapped: menu.close()
            }
        }

        DockMenu {
            id: menu
        }

        DockTooltip {
            id: tooltip

            // Chained x/y instead of mapToItem: these stay live, so the tooltip
            // rides along with the dock's slide-in and with drag reorders.
            readonly property real centerX: root.hoveredEntry ? dock.x + content.x + root.hoveredEntry.x + root.hoveredEntry.width / 2 : 0

            name: root.hoveredEntry ? (root.hoveredEntry.modelData.entry?.name ?? root.hoveredEntry.modelData.appId) : ""
            appId: root.hoveredEntry ? root.hoveredEntry.modelData.appId : ""

            x: Math.max(8, Math.min(root.width - width - 8, centerX - width / 2))
            y: root.hoveredEntry ? dock.y + content.y + root.hoveredEntry.y - height - 8 : 0
        }
    }
}
