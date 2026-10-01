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

    // Rows of { wallpaperId, url, thumb, preview, resolution, fileSize },
    // appended to as further pages are loaded. A ListModel rather than a JS
    // array: assigning a new array makes the grid rebuild from scratch and
    // throws the scroll position back to the top on every page.
    //
    // Only the rows that pass `Config.wallhaven.hideDownloaded` are in it;
    // everything fetched is kept in `_all`, so the filter can be flipped
    // without searching again.
    readonly property alias results: resultsModel
    // Fetched rows the filter is currently leaving out.
    readonly property int hiddenCount: root._all.length - resultsModel.count
    property var _all: []
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
        root._sync();
    }

    function _visible(row) {
        return !Config.wallhaven.hideDownloaded || root.downloadedIds[row.wallpaperId] !== true;
    }

    // Bring the model in line with `_all` under the current filter, row by row
    // rather than clear-and-refill, so the grid keeps its scroll position and
    // only the cards that actually come or go are rebuilt.
    function _sync() {
        const wanted = root._all.filter(row => root._visible(row));
        const keep = ({});
        for (const row of wanted) {
            keep[row.wallpaperId] = true;
        }

        let i = 0;
        for (const row of wanted) {
            // Rows the filter now drops sit in the way of the next wanted one.
            while (i < resultsModel.count && keep[resultsModel.get(i).wallpaperId] !== true) {
                resultsModel.remove(i);
            }
            if (i >= resultsModel.count || resultsModel.get(i).wallpaperId !== row.wallpaperId) {
                resultsModel.insert(i, row);
            }
            i++;
        }
        if (i < resultsModel.count) {
            resultsModel.remove(i, resultsModel.count - i);
        }
    }

    Component.onCompleted: root._rebuildDownloaded()

    Connections {
        target: Config.wallhaven

        function onHideDownloadedChanged() {
            root._sync();
        }
    }

    // A finished download lands in the folder the model is watching, so the
    // count is what says a new one arrived.
    Connections {
        target: WallpaperService.imageModel

        function onCountChanged() {
            root._rebuildDownloaded();
        }
    }

    readonly property bool hasMore: root.page > 0 && root.page < root.lastPage

    // Tags of one wallpaper, which search results do not carry: a request of
    // their own, so they are only looked up for the one being previewed.
    // `tags` is a list of { id, name, category, purity } for `tagsId`.
    property string tagsId: ""
    property var tags: []
    property bool tagsLoading: false
    property string tagsError: ""

    function fetchTags(wallpaperId) {
        if (wallpaperId === root.tagsId && (root.tagsLoading || root.tagsError === ""))
            return;

        const command = ["python3", Quickshell.shellPath("Helpers/wallhaven.py"), "info", "--id", wallpaperId];
        if (Config.wallhaven.apiKey) {
            command.push("--api-key", Config.wallhaven.apiKey);
        }

        root.tagsId = wallpaperId;
        root.tags = [];
        root.tagsError = "";
        root.tagsLoading = true;

        tagger.running = false;
        tagger.wallpaperId = wallpaperId;
        tagger.command = command;
        tagger.running = true;
    }

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
        root._all = [];
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

                const rows = searcher.page === 1 ? [] : root._all.slice();
                // Random listings and new uploads can shift a result onto the
                // next page too; a second copy would break the id-keyed sync.
                const seen = ({});
                for (const row of rows) {
                    seen[row.wallpaperId] = true;
                }
                for (const result of payload.results) {
                    if (seen[result.id]) {
                        continue;
                    }
                    seen[result.id] = true;
                    rows.push({
                        // `id` is taken by QML, so the wallpaper's own id is
                        // carried under a name a delegate can bind to.
                        wallpaperId: result.id,
                        url: result.url,
                        thumb: result.thumb,
                        preview: result.preview || result.thumb,
                        resolution: result.resolution,
                        fileSize: result.fileSize || 0
                    });
                }
                root._all = rows;
                root._sync();
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
        id: tagger
        running: false

        // Which wallpaper this run was for, so a preview flicked past before
        // its tags arrived does not get the previous one's.
        property string wallpaperId: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (tagger.wallpaperId !== root.tagsId || this.text.trim() === "") {
                    return;
                }

                root.tagsLoading = false;

                let payload;
                try {
                    payload = JSON.parse(this.text);
                } catch (e) {
                    root.tagsError = "Could not read the tags";
                    console.log("[wallhaven] Failed to parse tags:", e);
                    return;
                }

                if (!payload.ok) {
                    root.tagsError = payload.error || "Could not load the tags";
                    return;
                }

                root.tags = payload.tags;
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
