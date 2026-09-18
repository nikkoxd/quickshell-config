pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Core

// Search and download side of wallhaven.cc, driven by Helpers/wallhaven.py.
// Nothing here touches the wallpaper that is set — WallpaperBrowser decides
// what to do with a finished download.
Singleton {
    id: root

    // Rows of { wallpaperId, url, thumb, resolution }, appended to as further
    // pages are loaded. A ListModel rather than a JS array: assigning a new
    // array makes the grid rebuild from scratch and throws the scroll position
    // back to the top on every page.
    readonly property alias results: resultsModel
    property bool loading: false
    property string error: ""
    property int page: 0
    property int lastPage: 1
    property int total: 0

    // The wallpaper id currently being fetched, or "" — one download at a time,
    // so a double click cannot start the same fetch twice.
    property string downloadingId: ""

    // Ids already sitting in the local wallpaper folder, keyed for lookup from
    // a delegate. Downloads keep Wallhaven's own file name, so the folder
    // listing is all it takes to recognise them.
    property var downloadedIds: ({})

    readonly property var _downloadedName: /^wallhaven-([A-Za-z0-9]+)\./

    function _rebuildDownloaded() {
        const model = WallpaperService.imageModel;
        const ids = ({});

        for (let i = 0; i < model.count; i++) {
            const match = root._downloadedName.exec(model.get(i, "fileName") || "");
            if (match) {
                ids[match[1]] = true;
            }
        }

        root.downloadedIds = ids;
    }

    Component.onCompleted: root._rebuildDownloaded()

    // A finished download lands in the folder the model is watching, so the
    // count is what says a new one arrived.
    Connections {
        target: WallpaperService.imageModel

        function onCountChanged() {
            root._rebuildDownloaded();
        }
    }

    readonly property bool hasMore: root.page > 0 && root.page < root.lastPage

    signal downloaded(string path, bool existed)
    signal downloadFailed(string message)

    // Aspect ratios Wallhaven accepts. "" is no filter at all; the rest go
    // straight into the `ratios` API parameter.
    readonly property var ratios: [
        {
            label: "Any ratio",
            value: ""
        },
        {
            label: "Landscape",
            value: "landscape"
        },
        {
            label: "Portrait",
            value: "portrait"
        },
        {
            label: "16 × 9",
            value: "16x9"
        },
        {
            label: "16 × 10",
            value: "16x10"
        },
        {
            label: "21 × 9",
            value: "21x9"
        },
        {
            label: "4 × 3",
            value: "4x3"
        },
        {
            label: "1 × 1",
            value: "1x1"
        }
    ]

    readonly property var sortings: [
        {
            label: "Latest",
            value: "date_added"
        },
        {
            label: "Relevance",
            value: "relevance"
        },
        {
            label: "Random",
            value: "random"
        },
        {
            label: "Views",
            value: "views"
        },
        {
            label: "Favorites",
            value: "favorites"
        },
        {
            label: "Toplist",
            value: "toplist"
        }
    ]

    // Bumped on every search so a page that arrives after the query changed is
    // dropped instead of appended to results it does not belong to.
    property int _token: 0
    property string _seed: ""

    ListModel {
        id: resultsModel
    }

    function search(query) {
        root._seed = "";
        resultsModel.clear();
        root.page = 0;
        root.lastPage = 1;
        root.total = 0;
        root._fetch(query, 1);
    }

    function loadMore() {
        if (root.loading || !root.hasMore) {
            return;
        }

        root._fetch(Config.wallhaven.query, root.page + 1);
    }

    function _fetch(query, page) {
        const command = ["python3", Quickshell.shellPath("Helpers/wallhaven.py"), "search", "--query", query || "", "--page", String(page), "--categories", Config.wallhaven.categories, "--purity", Config.wallhaven.purity, "--sorting", Config.wallhaven.sorting, "--top-range", Config.wallhaven.topRange];

        if (Config.wallhaven.ratios) {
            command.push("--ratios", Config.wallhaven.ratios);
        }
        if (root._seed) {
            command.push("--seed", root._seed);
        }
        if (Config.wallhaven.apiKey) {
            command.push("--api-key", Config.wallhaven.apiKey);
        }

        root._token++;
        root.error = "";
        root.loading = true;

        searcher.running = false;
        searcher.token = root._token;
        searcher.page = page;
        searcher.command = command;
        searcher.running = true;
    }

    function download(wallpaperId, url) {
        if (!url || root.downloadingId !== "") {
            return;
        }

        root.downloadingId = wallpaperId;
        downloader.running = false;
        downloader.command = ["python3", Quickshell.shellPath("Helpers/wallhaven.py"), "download", "--url", url, "--dest", Config.wallpaper.staticWallpaperFolder];
        downloader.running = true;
    }

    Process {
        id: searcher
        running: false

        // The token and page this run was started for, so a result that lands
        // after the query changed can be told apart from a current one.
        property int token: -1
        property int page: 1

        stdout: StdioCollector {
            onStreamFinished: {
                // A run that was killed to make way for a newer query finishes
                // with nothing to say; the newer one owns `loading` now.
                if (searcher.token !== root._token || this.text.trim() === "") {
                    return;
                }

                root.loading = false;

                let payload;
                try {
                    payload = JSON.parse(this.text);
                } catch (e) {
                    root.error = "Could not read the Wallhaven response";
                    console.log("[wallhaven] Failed to parse response:", e);
                    return;
                }

                if (!payload.ok) {
                    root.error = payload.error || "Search failed";
                    return;
                }

                if (searcher.page === 1) {
                    resultsModel.clear();
                }
                for (let i = 0; i < payload.results.length; i++) {
                    const result = payload.results[i];
                    resultsModel.append({
                        // `id` is taken by QML, so the wallpaper's own id is
                        // carried under a name a delegate can bind to.
                        wallpaperId: result.id,
                        url: result.url,
                        thumb: result.thumb,
                        resolution: result.resolution
                    });
                }
                root.page = payload.page;
                root.lastPage = payload.lastPage;
                root.total = payload.total;
                root._seed = payload.seed || root._seed;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) {
                    console.log("[wallhaven]", this.text.trim());
                }
            }
        }
    }

    Process {
        id: downloader
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.downloadingId = "";

                let payload;
                try {
                    payload = JSON.parse(this.text);
                } catch (e) {
                    root.downloadFailed("Could not read the download response");
                    console.log("[wallhaven] Failed to parse download response:", e);
                    return;
                }

                if (!payload.ok) {
                    root.downloadFailed(payload.error || "Download failed");
                    return;
                }

                console.log("[wallhaven] Downloaded", payload.path);
                root.downloaded(payload.path, payload.existed || false);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) {
                    console.log("[wallhaven]", this.text.trim());
                }
            }
        }
    }
}
