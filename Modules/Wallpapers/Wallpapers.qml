pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import qs.Core

View {
    id: root
    implicitWidth: carouselContainer.implicitWidth
    implicitHeight: hoverHandler.hovered ? 280 : 240
    focused: true
    dismissable: false
    displayInFullscreen: true
    property var wallpaperType: Wallpapers.Type.Image

    onWallpaperTypeChanged: {
        if (wallpaperType === Wallpapers.Type.Mpvpaper && videoWallpapersModel.count === 0) {
            videoLister.running = true;
        }
        carousel.currentIndex = 0;
    }

    enum Type {
        Image,
        Mpvpaper
    }

    function expandPath(path) {
        return path.replace(/\$\{?(\w+)\}?/g, function (match, varName) {
            var value = Quickshell.env(varName);
            return value !== null ? value : match;
        });
    }

    function setWallpaper(wallpaper) {
        Config.theme.wallpaper = wallpaper;
        if (wallpaperType === Wallpapers.Type.Image) {
            Quickshell.execDetached(["awww", "img", wallpaper, "-t", "random", "--transition-fps", "60"]);
        } else if (wallpaperType === Wallpapers.Type.Mpvpaper) {
            const output = Config.theme.output;
            const cmd = "killall mpvpaper 2>/dev/null; sleep 0.3; exec mpvpaper '" + output + "' '" + wallpaper + "' -o 'no-audio loop-file=inf'";
            Quickshell.execDetached(["sh", "-c", cmd]);
        }
    }

    function getCurrentWallpaperPath() {
        if (wallpaperType === Wallpapers.Type.Image) {
            return imageWallpapersModel.get(carousel.currentIndex, "filePath");
        } else {
            return videoWallpapersModel.get(carousel.currentIndex).filePath;
        }
    }

    function syncCarouselIndex() {
        console.log("Syncing carousel index");

        let model = carousel.model;
        if (model.count === 0) {
            console.log("No wallpapers found");
            return;
        }

        let target = Config.theme.wallpaper;
        console.log("Target wallpaper:", target);

        for (let i = 0; i < model.count; i++) {
            let item;
            if (wallpaperType === Wallpapers.Type.Image) {
                item = model.get(i, "filePath");
            } else {
                item = model.get(i).filePath;
            }
            if (item && item === target) {
                console.log("Syncing carousel index to:", i);
                Qt.callLater(() => carousel.currentIndex = i);
                return;
            }
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            const wallpaper = root.getCurrentWallpaperPath();
            root.setWallpaper(wallpaper);
        }
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

    HoverHandler {
        id: hoverHandler
    }

    FolderListModel {
        id: imageWallpapersModel
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

    ListModel {
        id: videoWallpapersModel
    }

    Process {
        id: videoLister
        command: ["python3", Quickshell.shellPath("Helpers/list_walls.py")]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    videoWallpapersModel.clear();
                    for (let i = 0; i < data.length; i++) {
                        videoWallpapersModel.append({
                            preview: data[i].preview,
                            filePath: data[i].file
                        });
                    }
                    Qt.callLater(root.syncCarouselIndex);
                } catch (e) {
                    console.log("Failed to parse video wallpapers:", e);
                }
            }
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
                model: root.wallpaperType === Wallpapers.Type.Image ? imageWallpapersModel : videoWallpapersModel
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

        Row {
            id: typeSwitchContainer
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            visible: hoverHandler.hovered

            ThemedText {
                text: "Images"
                color: root.wallpaperType === Wallpapers.Type.Image ? "white" : "#888888"
                font.bold: root.wallpaperType === Wallpapers.Type.Image
                anchors.verticalCenter: parent.verticalCenter
            }

            Switch {
                id: typeSwitch
                anchors.verticalCenter: parent.verticalCenter
                checked: root.wallpaperType === Wallpapers.Type.Mpvpaper

                onCheckedChanged: {
                    root.wallpaperType = checked ? Wallpapers.Type.Mpvpaper : Wallpapers.Type.Image;
                }
            }

            ThemedText {
                text: "mpvpaper"
                color: root.wallpaperType === Wallpapers.Type.Mpvpaper ? "white" : "#888888"
                font.bold: root.wallpaperType === Wallpapers.Type.Mpvpaper
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
