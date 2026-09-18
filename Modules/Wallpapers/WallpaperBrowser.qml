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

    function search() {
        root.status = "";
        Config.wallhaven.query = root.query;
        WallhavenService.search(root.query);
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
            cellWidth: (width - 14) / 5
            cellHeight: root.contentWidth / 5 * 0.62
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

            delegate: WallpaperBrowserDelegate {
                id: delegateItem
                required property string wallpaperId
                required property string url

                width: grid.cellWidth
                height: grid.cellHeight
                downloading: WallhavenService.downloadingId === delegateItem.wallpaperId
                downloaded: WallhavenService.downloadedIds[delegateItem.wallpaperId] === true
                // The download keeps Wallhaven's own file name, so the wallpaper
                // on screen can be matched back to the result it came from.
                current: (Config.wallpaper.current || "").includes("wallhaven-" + delegateItem.wallpaperId + ".")
                onClicked: WallhavenService.download(delegateItem.wallpaperId, delegateItem.url)
            }

            ThemedText {
                anchors.centerIn: parent
                visible: WallhavenService.results.count === 0
                text: WallhavenService.loading ? "Searching…" : WallhavenService.error || "No wallpapers found"
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
                    if (WallhavenService.total > 0)
                        return WallhavenService.results.count + " of " + WallhavenService.total;
                    return "";
                }
                color: Qt.alpha(Config.colorscheme.fg, 0.6)
                font.pixelSize: Config.theme.fontSize * 0.9
            }
        }
    }
}
