pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: carouselContainer.implicitWidth
    // The theme list expands inside the island window rather than in a popup
    // of its own, so the view has to make room for it. Bar.qml animates the
    // resize.
    implicitHeight: 280 + (themeSelector.expanded ? themeSelector.listHeight : 0)
    focused: true
    dismissable: false
    displayInFullscreen: true

    // What is being browsed ("image" | "video" | "both") — separate from
    // Config.wallpaper.type, which is the type of the wallpaper that is set.
    // Read-only: the pill writes the config, so a config reload is never fought
    // by a write-back from here.
    readonly property string filter: Config.wallpaper.selectorFilter

    onFilterChanged: WallpaperService.requestModelUpdate(filter)

    Component.onCompleted: {
        WallpaperService.requestModelUpdate(filter);
        syncCarouselIndex();
    }

    function syncCarouselIndex() {
        let model = carousel.model;
        if (model.count === 0) {
            console.log("[wallpapers] No wallpapers found");
            return;
        }

        let target = Config.wallpaper.current;
        for (let i = 0; i < model.count; i++) {
            // FolderListModel needs a role name, ListModel returns the row.
            let item;
            if (filter === "image") {
                item = model.get(i, "filePath");
            } else {
                item = model.get(i).filePath;
            }
            if (item && item === target) {
                Qt.callLater(() => carousel.currentIndex = i);
                return;
            }
        }
    }

    Connections {
        target: WallpaperService
        function onModelUpdateDone() {
            root.syncCarouselIndex();
        }
    }

    function setWallpaperAt(index) {
        const wallpaper = WallpaperService.getWallpaper(index, root.filter);
        if (!wallpaper) {
            return;
        }

        WallpaperService.setWallpaper(wallpaper.path, wallpaper.type);
    }

    Shortcut {
        sequence: "Return"
        onActivated: root.setWallpaperAt(carousel.currentIndex)
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            if (carousel.currentIndex > 0)
                carousel.currentIndex--;
            else
                carousel.currentIndex = carousel.count - 1;
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (carousel.currentIndex < carousel.count - 1)
                carousel.currentIndex++;
            else
                carousel.currentIndex = 0;
        }
    }

    Column {
        id: mainLayout
        y: Config.island.padding
        spacing: 24

        Item {
            id: carouselContainer
            implicitWidth: 900
            implicitHeight: 160
            anchors.horizontalCenter: parent.horizontalCenter
            clip: false

            PathView {
                id: carousel
                anchors.fill: parent
                model: WallpaperService.getModel(root.filter)
                pathItemCount: 7

                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                snapMode: PathView.SnapToItem

                onCurrentIndexChanged: console.log("Current index:", currentIndex)

                path: Path {
                    startX: -carousel.width / 4
                    startY: carousel.height / 2

                    PathAttribute {
                        name: "iconScale"
                        value: 0
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 0
                    }

                    PathLine {
                        x: 0
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: 0.6
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 1
                    }

                    PathLine {
                        x: carousel.width / 2
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: 1.2
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 10
                    }

                    PathLine {
                        x: carousel.width
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: 0.6
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 1
                    }

                    PathLine {
                        x: carousel.width + carousel.width / 4
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: 0
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 0
                    }
                }

                delegate: WallpaperSelectorDelegate {
                    onClicked: index => {
                        root.setWallpaperAt(index);
                        root.syncCarouselIndex();
                    }
                }
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    if (event.angleDelta.y < 0 || event.angleDelta.x < 0) {
                        if (carousel.currentIndex < carousel.count - 1)
                            carousel.currentIndex++;
                        else
                            carousel.currentIndex = 0;
                    } else {
                        if (carousel.currentIndex > 0)
                            carousel.currentIndex--;
                        else
                            carousel.currentIndex = carousel.count - 1;
                    }
                    event.accepted = true;
                }
            }
        }

        Item {
            id: controls
            width: carouselContainer.implicitWidth - Config.island.padding
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: Math.max(filterPill.height, themeSelector.height)

            SegmentPill {
                id: filterPill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                current: root.filter
                options: [
                    {
                        label: "Image",
                        value: "image"
                    },
                    {
                        label: "Video",
                        value: "video"
                    },
                    {
                        label: "Both",
                        value: "both"
                    }
                ]
                onSelected: value => Config.wallpaper.selectorFilter = value
            }

            Dropdown {
                id: themeSelector
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: filterPill.height
                horizontalPadding: 16
                options: ThemeService.names
                current: Config.theme.colorscheme
                onSelected: value => Config.theme.colorscheme = value
            }
        }
    }
}
