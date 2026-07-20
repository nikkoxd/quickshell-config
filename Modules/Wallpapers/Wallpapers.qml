pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: carouselContainer.implicitWidth
    implicitHeight: 280
    focused: true
    dismissable: false
    displayInFullscreen: true

    property var wallpaperType: WallpaperService.toType(Config.wallpaper.type)
    onWallpaperTypeChanged: WallpaperService.requestModelUpdate(wallpaperType);

    Component.onCompleted: syncCarouselIndex()

    function syncCarouselIndex() {
        console.log("Syncing carousel index");

        let model = carousel.model;
        if (model.count === 0) {
            console.log("No wallpapers found");
            return;
        }

        let target = Config.wallpaper.current;
        console.log("Target wallpaper:", target);

        for (let i = 0; i < model.count; i++) {
            let item;
            if (wallpaperType === WallpaperService.Type.Image) {
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

    Connections {
        target: WallpaperService
        function onModelUpdateDone() {
            root.syncCarouselIndex();
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            const wallpaper = WallpaperService.getWallpaperPath(carousel.currentIndex, root.wallpaperType);
            WallpaperService.setWallpaper(wallpaper, root.wallpaperType);
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
                model: WallpaperService.getModel(root.wallpaperType)
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
                    onClicked: (wallpaper) => {
                        WallpaperService.setWallpaper(wallpaper, root.wallpaperType);
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

        Row {
            id: typeSwitchContainer
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            ThemedText {
                text: "awww"
                color: root.wallpaperType === WallpaperService.Type.Image ? "white" : "#888888"
                font.bold: root.wallpaperType === WallpaperService.Type.Image
                anchors.verticalCenter: parent.verticalCenter
            }

            Switch {
                id: typeSwitch
                anchors.verticalCenter: parent.verticalCenter
                checked: root.wallpaperType === WallpaperService.Type.Mpvpaper

                onCheckedChanged: {
                    root.wallpaperType = checked ? WallpaperService.Type.Mpvpaper : WallpaperService.Type.Image;
                }
            }

            ThemedText {
                text: "mpvpaper"
                color: root.wallpaperType === WallpaperService.Type.Mpvpaper ? "white" : "#888888"
                font.bold: root.wallpaperType === WallpaperService.Type.Mpvpaper
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
