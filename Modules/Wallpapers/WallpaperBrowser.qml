pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import qs.Core
import qs.Services

// Browse an online wallpaper source and download into the local folder. Only
// wallhaven.cc is wired up; the source dropdown is where a second one would go.
View {
    id: root
    implicitWidth: mainLayout.width + root.padding * 2
    implicitHeight: mainLayout.implicitHeight + root.padding * 2
    focused: true
    dismissable: false
    displayInFullscreen: true

    readonly property real padding: Config.island.padding / 2
    readonly property real contentWidth: 940

    // Wallhaven takes categories and purity as three bits each:
    // general/anime/people and sfw/sketchy/nsfw.
    function bitSet(bits, index) {
        return bits.charAt(index) === "1";
    }

    // Flipping the last remaining bit off would make the API reject the query,
    // so the final one on stays on.
    function toggleBit(bits, index) {
        const flipped = bitSet(bits, index) ? "0" : "1";
        const next = bits.substring(0, index) + flipped + bits.substring(index + 1);
        return next.includes("1") ? next : bits;
    }

    // NSFW results are only served to a logged-in key.
    readonly property bool nsfwAllowed: Config.wallhaven.apiKey !== ""

    property string status: ""

    // What is in the search field. Only written back to the config once a
    // search actually runs, so a keystroke does not rewrite wallhaven.json.
    property string query: ""

    // The result open in the preview, or null. A copy of the row rather than
    // the delegate, which the filter can take away while the preview is open.
    property var previewing: null

    function search() {
        root.status = "";
        Config.wallhaven.query = root.query;
        WallhavenService.search(root.query);
    }

    function download(wallpaper) {
        WallhavenService.download(wallpaper.wallpaperId, wallpaper.url);
    }

    function openPreview(wallpaper) {
        root.previewing = {
            wallpaperId: wallpaper.wallpaperId,
            url: wallpaper.url,
            preview: wallpaper.preview,
            resolution: wallpaper.resolution,
            fileSize: wallpaper.fileSize
        };
        WallhavenService.fetchTags(wallpaper.wallpaperId);
    }

    function closePreview() {
        root.previewing = null;
        searchInput.forceActiveFocus();
    }

    // Pages are pulled in as the end of the grid scrolls into view, which never
    // happens when there is nothing to scroll: a filter that hides most of a
    // page leaves it short. Keep loading until it overflows or runs out.
    function fillGrid() {
        if (grid.atYEnd && !WallhavenService.loading && !WallhavenService.error)
            WallhavenService.loadMore();
    }

    Component.onCompleted: {
        root.query = Config.wallhaven.query;
        searchInput.text = Config.wallhaven.query;
        root.search();
        searchInput.forceActiveFocus();
    }

    // Filter changes re-run the query from the first page.
    Connections {
        target: Config.wallhaven

        function onCategoriesChanged() {
            root.search();
        }
        function onPurityChanged() {
            root.search();
        }
        function onSortingChanged() {
            root.search();
        }
        function onRatiosChanged() {
            root.search();
        }
    }

    Connections {
        target: WallhavenService

        function onDownloaded(path, existed) {
            WallpaperService.setWallpaper(path, WallpaperService.Type.Image);
            root.status = existed ? "Already downloaded — applied" : "Downloaded and applied";
            if (root.previewing)
                root.closePreview();
        }

        function onLoadingChanged() {
            Qt.callLater(root.fillGrid);
        }

        function onDownloadFailed(message) {
            root.status = message;
        }
    }

    Timer {
        id: queryDebounce
        interval: 500
        onTriggered: root.search()
    }

    Column {
        id: mainLayout
        y: root.padding
        x: root.padding
        width: root.contentWidth
        spacing: 12

        ViewHeader {
            id: header
            width: parent.width
            // Above the grid, which is painted after it, so an open dropdown is
            // not covered by the thumbnails.
            z: 2
            text: "Download wallpapers"

            IconButton {
                icon: "eye"
                activeIcon: "eye-slash"
                active: Config.wallhaven.hideDownloaded
                onClicked: Config.wallhaven.hideDownloaded = !Config.wallhaven.hideDownloaded
            }

            Dropdown {
                id: ratioSelector
                height: 30
                horizontalPadding: 16
                options: WallhavenService.ratios
                current: Config.wallhaven.ratios
                onSelected: value => Config.wallhaven.ratios = value
            }

            Dropdown {
                id: sortSelector
                height: 30
                horizontalPadding: 16
                options: WallhavenService.sortings
                current: Config.wallhaven.sorting
                onSelected: value => Config.wallhaven.sorting = value
            }

            Dropdown {
                id: sourceSelector
                height: 30
                horizontalPadding: 16
                options: [
                    {
                        label: "Wallhaven",
                        value: "wallhaven"
                    }
                ]
                current: Config.wallpaper.downloadSource
                onSelected: value => Config.wallpaper.downloadSource = value
            }
        }

        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                width: 260
                height: 32
                radius: height / 2
                color: Config.colorscheme.surface
                anchors.verticalCenter: parent.verticalCenter

                ThemedText {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    icon: true
                    text: "magnifying-glass"
                    color: Qt.alpha(Config.colorscheme.fg, 0.6)
                }

                TextField {
                    id: searchInput
                    anchors.left: searchIcon.right
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    borderless: true
                    horizontalPadding: 8
                    backgroundImplicitHeight: 32
                    placeholderText: "Search Wallhaven…"
                    onTextChanged: {
                        if (text === root.query)
                            return;
                        root.query = text;
                        queryDebounce.restart();
                    }
                    onAccepted: {
                        queryDebounce.stop();
                        root.search();
                    }
                    Keys.onEscapePressed: root.closeRequested()
                }
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        {
                            label: "General",
                            index: 0
                        },
                        {
                            label: "Anime",
                            index: 1
                        },
                        {
                            label: "People",
                            index: 2
                        }
                    ]

                    Chip {
                        required property var modelData
                        text: modelData.label
                        active: root.bitSet(Config.wallhaven.categories, modelData.index)
                        onClicked: Config.wallhaven.categories = root.toggleBit(Config.wallhaven.categories, modelData.index)
                    }
                }
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        {
                            label: "SFW",
                            index: 0
                        },
                        {
                            label: "Sketchy",
                            index: 1
                        },
                        {
                            label: "NSFW",
                            index: 2
                        }
                    ]

                    Chip {
                        required property var modelData
                        text: modelData.label
                        active: root.bitSet(Config.wallhaven.purity, modelData.index)
                        opacity: modelData.index === 2 && !root.nsfwAllowed ? 0.5 : 1
                        onClicked: {
                            if (modelData.index === 2 && !root.nsfwAllowed) {
                                root.status = "NSFW needs a Wallhaven API key — set it in Settings › Wallpaper";
                                return;
                            }
                            Config.wallhaven.purity = root.toggleBit(Config.wallhaven.purity, modelData.index);
                        }
                    }
                }
            }
        }

        GridView {
            id: grid
            width: parent.width
            height: 460
            clip: true
            readonly property int columns: Math.max(1, Config.wallhaven.columns)

            cellWidth: (width - 14) / columns
            cellHeight: root.contentWidth / columns * 0.62
            boundsBehavior: Flickable.StopAtBounds
            model: WallhavenService.results

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: scrollBar
                policy: grid.contentHeight > grid.height ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff

                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: Qt.alpha(Config.colorscheme.fg, scrollBar.pressed ? 0.6 : scrollBar.hovered ? 0.45 : 0.25)
                }

                background: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: Qt.alpha(Config.colorscheme.fg, 0.08)
                }
            }

            // Pull the next page in as the end comes into view, so the grid
            // reads as one long list instead of a pager.
            onAtYEndChanged: {
                if (atYEnd)
                    WallhavenService.loadMore();
            }

            // Fewer, bigger columns can leave a loaded page short of a
            // scrollable grid just the same as the filter can.
            onCountChanged: Qt.callLater(root.fillGrid)
            onColumnsChanged: Qt.callLater(root.fillGrid)

            delegate: WallpaperBrowserDelegate {
                id: delegateItem
                required property string wallpaperId
                required property string url
                required property string preview
                required property real fileSize

                width: grid.cellWidth
                height: grid.cellHeight
                downloading: WallhavenService.downloadingId === delegateItem.wallpaperId
                downloaded: WallhavenService.downloadedIds[delegateItem.wallpaperId] === true
                // The download keeps Wallhaven's own file name, so the wallpaper
                // on screen can be matched back to the result it came from.
                current: (Config.wallpaper.current || "").includes("wallhaven-" + delegateItem.wallpaperId + ".")
                onClicked: {
                    if (Config.wallhaven.previewBeforeDownload)
                        root.openPreview(delegateItem);
                    else
                        root.download(delegateItem);
                }
                onPreviewRequested: root.openPreview(delegateItem)
            }

            ThemedText {
                anchors.centerIn: parent
                visible: WallhavenService.results.count === 0
                text: {
                    if (WallhavenService.loading)
                        return "Searching…";
                    if (WallhavenService.error)
                        return WallhavenService.error;
                    return WallhavenService.hiddenCount > 0 ? "Everything here is already downloaded" : "No wallpapers found";
                }
                color: Qt.alpha(Config.colorscheme.fg, 0.6)
            }
        }

        Item {
            width: parent.width
            height: statusText.implicitHeight

            ThemedText {
                id: statusText
                anchors.left: parent.left
                text: {
                    if (WallhavenService.error)
                        return WallhavenService.error;
                    if (root.status)
                        return root.status;
                    if (WallhavenService.loading)
                        return "Searching…";
                    if (WallhavenService.total > 0) {
                        const shown = WallhavenService.results.count + " of " + WallhavenService.total;
                        return WallhavenService.hiddenCount > 0 ? shown + " · " + WallhavenService.hiddenCount + " downloaded hidden" : shown;
                    }
                    return "";
                }
                color: Qt.alpha(Config.colorscheme.fg, 0.6)
                font.pixelSize: Config.theme.fontSize * 0.9
            }
        }
    }

    // Laid over the whole browser rather than growing the island, so opening
    // and closing it does not resize anything underneath.
    Loader {
        x: mainLayout.x
        y: mainLayout.y
        width: mainLayout.width
        height: mainLayout.height
        active: root.previewing !== null
        focus: active

        // Handed over once rather than bound, so clearing `previewing` to close
        // does not leave the preview reading off null on its way out.
        onLoaded: item.wallpaper = root.previewing

        sourceComponent: WallpaperPreview {
            downloading: WallhavenService.downloadingId === wallpaper.wallpaperId
            downloaded: WallhavenService.downloadedIds[wallpaper.wallpaperId] === true
            readonly property bool ownTags: WallhavenService.tagsId === wallpaper.wallpaperId
            tags: ownTags ? WallhavenService.tags : []
            tagsLoading: ownTags && WallhavenService.tagsLoading
            tagsError: ownTags ? WallhavenService.tagsError : ""
            onDownloadRequested: root.download(wallpaper)
            onCloseRequested: root.closePreview()
            // Straight into the search field, so the query that ran is the one
            // on screen and can be edited from there.
            onTagClicked: name => {
                root.closePreview();
                root.query = name;
                searchInput.text = name;
                queryDebounce.stop();
                root.search();
            }
        }
    }
}
