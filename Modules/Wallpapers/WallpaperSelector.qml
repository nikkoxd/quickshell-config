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
    implicitHeight: {
        const base = root.padding * 2 + mainLayout.implicitHeight;
        if (!themeSelector.expanded)
            return base;
        return Math.max(base, root.padding * 2 + header.height + themeSelector.listHeight);
    }
    focused: true
    dismissable: false
    displayInFullscreen: true
    closeOnUnhover: true

    readonly property real padding: Config.island.padding / 2

    // The generator the colorscheme names, if any: only those have a mode.
    readonly property string generator: {
        const name = Config.theme.colorscheme;
        return ThemeService.generators.includes(name) ? name : "";
    }
    readonly property bool generatorDark: root.generator === "Iris" ? Config.iris.dark : Config.matugen.dark

    // Auto mode picks the mode from the wallpaper, so asking for one explicitly
    // has to turn it off, and the colors have to be generated again: nothing
    // watches these two flags the way it watches the colorscheme.
    function toggleMode() {
        const settings = root.generator === "Iris" ? Config.iris : Config.matugen;
        settings.autoMode = false;
        settings.dark = !settings.dark;
        WallpaperService.generateColors(WallpaperService.colorSource());
    }

    // What is being browsed ("image" | "video" | "both") — separate from
    // Config.wallpaper.type, which is the type of the wallpaper that is set.
    // Read-only: the pill writes the config, so a config reload is never fought
    // by a write-back from here.
    readonly property string filter: Config.wallpaper.selectorFilter

    // Listing order: "recent" (newest first) or "random". Read-only for the
    // same reason as the filter — the button writes the config.
    readonly property string sort: Config.wallpaper.selectorSort

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
            const wallpaper = WallpaperService.getWallpaper(i, root.filter);
            if (wallpaper && wallpaper.path === target) {
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
        y: root.padding

        ViewHeader {
            id: header
            width: carouselContainer.implicitWidth - Config.island.padding
            anchors.horizontalCenter: parent.horizontalCenter
            // Above the carousel, which is painted after it, so the open theme
            // list is not covered by the wallpaper thumbnails.
            z: 1
            text: "Wallpapers"

            // Not a toggle: the icon alone says which order is on, so it never
            // takes the accent highlight. A new shuffle every time random is
            // picked, so pressing it again reorders instead of doing nothing.
            IconButton {
                icon: root.sort === "random" ? "shuffle" : "clock-counter-clockwise"
                width: height
                height: themeSelector.height
                onClicked: Config.wallpaper.selectorSort = root.sort === "random" ? "recent" : "random"
            }

            // Only the generators render a light and a dark variant; a static
            // theme is whatever its file says it is.
            IconButton {
                icon: "sun"
                activeIcon: "moon"
                active: root.generatorDark
                visible: root.generator !== ""
                width: height
                height: themeSelector.height
                onClicked: root.toggleMode()
            }

            Dropdown {
                id: themeSelector
                // Matches the header buttons in the other views.
                height: 30
                horizontalPadding: 16
                options: ThemeService.names
                current: Config.theme.colorscheme
                onSelected: value => Config.theme.colorscheme = value
            }
        }

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

                // Every wallpaper is drawn at the same size except the one in
                // focus. The extra points at a quarter and three quarters of the
                // width sit exactly where the neighbouring items rest, so the
                // scale only rises over the last step into the centre.
                readonly property real restScale: 0.8
                readonly property real focusScale: 1.2

                path: Path {
                    startX: -carousel.width / 4
                    startY: carousel.height / 2

                    PathAttribute {
                        name: "iconScale"
                        value: carousel.restScale
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 1
                    }

                    PathLine {
                        x: 0
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: carousel.restScale
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 1
                    }

                    PathLine {
                        x: carousel.width / 4
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: carousel.restScale
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
                        value: carousel.focusScale
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 10
                    }

                    PathLine {
                        x: carousel.width * 3 / 4
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: carousel.restScale
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 1
                    }

                    PathLine {
                        x: carousel.width
                        y: carousel.height / 2
                    }
                    PathAttribute {
                        name: "iconScale"
                        value: carousel.restScale
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
                        value: carousel.restScale
                    }
                    PathAttribute {
                        name: "iconZ"
                        value: 1
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
            width: 1
            height: 24
        }

        SegmentPill {
            id: filterPill
            verticalPadding: 6
            anchors.horizontalCenter: parent.horizontalCenter
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
    }
}
