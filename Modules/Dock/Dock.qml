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

        readonly property bool revealed: !Config.dock.onlyOnHover || (Config.dock.showWhenWorkspaceClear && workspaceClear) || dockHover.hovered || hotzoneHover.hovered || menu.visible || dragging

        // Reordering is previewed by displacing the other icons and only
        // committed to DockService on drop. ScriptModel is free to answer a
        // reorder by reassigning modelData on the delegates it already has
        // instead of moving them, which mid-drag would swap the dragged app for
        // its neighbour and leave `index` stale, so the model must not change
        // while a drag is in flight.
        property int dragIndex: -1
        property int dropIndex: -1
        readonly property bool dragging: dragIndex >= 0

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
                    // ScriptModel diffs the array so unchanged apps keep their
                    // delegate. It does not promise to *move* a delegate on a
                    // reorder though — it may equally reassign modelData on the
                    // delegates already in place — so nothing may assume a
                    // delegate keeps its app across an update.
                    model: ScriptModel {
                        values: DockService.items
                        objectProp: "appId"
                    }

                    DockEntry {
                        id: entry
                        size: Config.dock.iconSize

                        dockDragging: root.dragging

                        // Icons between the dragged one and the slot it would
                        // land on step aside by one place.
                        shiftSlots: {
                            if (root.dragIndex < 0 || entry.index === root.dragIndex)
                                return 0;
                            if (entry.index > root.dragIndex && entry.index <= root.dropIndex)
                                return -1;
                            if (entry.index < root.dragIndex && entry.index >= root.dropIndex)
                                return 1;
                            return 0;
                        }

                        // HoverHandler doesn't block, so the entry sitting under
                        // the dragged icon reports a hover too. Ignore hovers
                        // outright while a drag is running.
                        onHoveredChanged: {
                            if (entry.hovered && !root.dragging)
                                root.hoveredEntry = entry;
                            else if (root.hoveredEntry === entry)
                                root.hoveredEntry = null;
                        }

                        onDragStarted: {
                            root.dragIndex = entry.index;
                            root.dropIndex = entry.index;
                        }

                        onDragMoved: centerX => root.dropIndex = root.indexAt(centerX)

                        onDragFinished: {
                            if (root.dropIndex >= 0 && root.dropIndex !== root.dragIndex)
                                DockService.move(root.dragIndex, root.dropIndex);
                            root.dragIndex = -1;
                            root.dropIndex = -1;
                            DockService.persistOrder();
                        }

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
