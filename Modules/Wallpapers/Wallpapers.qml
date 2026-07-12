pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.Core

View {
    id: root
    implicitWidth: carouselContainer.implicitWidth
    implicitHeight: carouselContainer.implicitHeight + Config.island.padding * 2
    focused: true
    dismissable: false
    displayInFullscreen: true

    function expandPath(path) {
        return path.replace(/\$\{?(\w+)\}?/g, function (match, varName) {
            var value = Quickshell.env(varName);
            return value !== null ? value : match;
        });
    }

    function setWallpaper(wallpaper) {
        Config.theme.wallpaper = wallpaper;
        wallpaperSetter.command = ["awww", "img", wallpaper, "-t", "random", "--transition-fps", "60"];
        wallpaperSetter.running = true;
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            const wallpaper = wallpapersModel.get(carousel.currentIndex, "filePath");
            root.setWallpaper(wallpaper);
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            if (carousel.currentIndex > 0)
                carousel.currentIndex--;
            else
                carousel.currentIndex = wallpapersModel.count - 1;
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (carousel.currentIndex < wallpapersModel.count - 1)
                carousel.currentIndex++;
            else
                carousel.currentIndex = 0;
        }
    }

    FolderListModel {
        id: wallpapersModel
        folder: "file://" + root.expandPath(Config.theme.wallpaperFolder)
        nameFilters: ["*.jpg", "*.png"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Time
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                Qt.callLater(root.syncCarouselIndex);
            }
        }
    }

    Process {
        id: wallpaperSetter
        running: false
    }

    function syncCarouselIndex() {
        console.log("Syncing carousel index");

        if (wallpapersModel.count === 0) {
            console.log("No wallpapers found");
            return;
        }

        let target = Config.theme.wallpaper;
        console.log("Target wallpaper:", target);
        for (let i = 0; i < wallpapersModel.count; i++) {
            let item = wallpapersModel.get(i, "filePath");
            if (item && item === target) {
                console.log("Syncing carousel index to:", i);
                Qt.callLater(() => carousel.currentIndex = i);
                return;
            }
        }
    }

    Item {
        id: carouselContainer
        implicitWidth: 900
        implicitHeight: 160
        anchors.centerIn: parent
        clip: false

        PathView {
            id: carousel
            anchors.fill: parent
            model: wallpapersModel
            pathItemCount: 7

            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            snapMode: PathView.SnapToItem

            onCurrentIndexChanged: console.log("Current index:", currentIndex)

            path: Path {
                // Start outside the left edge
                startX: -carousel.width / 4
                startY: carousel.height / 2

                PathAttribute { name: "iconScale"; value: 0 }
                PathAttribute { name: "iconZ"; value: 0 }

                PathLine {
                    x: 0
                    y: carousel.height / 2
                }
                PathAttribute { name: "iconScale"; value: 0.6 }
                PathAttribute { name: "iconZ"; value: 1 }

                PathLine {
                    x: carousel.width / 2
                    y: carousel.height / 2
                }
                PathAttribute { name: "iconScale"; value: 1.2 }
                PathAttribute { name: "iconZ"; value: 10 }

                PathLine {
                    x: carousel.width
                    y: carousel.height / 2
                }
                PathAttribute { name: "iconScale"; value: 0.6 }
                PathAttribute { name: "iconZ"; value: 1 }

                // End outside the right edge
                PathLine {
                    x: carousel.width + carousel.width / 4
                    y: carousel.height / 2
                }
                PathAttribute { name: "iconScale"; value: 0 }
                PathAttribute { name: "iconZ"; value: 0 }
            }

            delegate: WallpaperDelegate {
                onClicked: wallpaper => root.setWallpaper(wallpaper)
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
}
