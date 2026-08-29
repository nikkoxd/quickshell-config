pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import Qt.labs.folderlistmodel
import qs.Core

Singleton {
    id: root

    property bool paused: false;

    onPausedChanged: {
        console.log("[wallpaper]", paused ? "Pausing playback" : "Resuming playback");
    }

    readonly property string thumbnailPath: "/tmp/quickshell-island-thumbnail.jpg"
    property bool generatingThumbnail: false
    property string _thumbnailSource: ""
    property string _pendingThumbnail: ""
    property bool _colorsWaitForThumbnail: false

    enum Type {
        Image,
        Mpvpaper
    }

    // Available wallpaper transitions. Each name maps to
    // Modules/Wallpapers/Shaders/<name>.frag.qsb.
    readonly property var transitions: ["doom", "diagonal", "diagonalWave", "circleRandom"]

    signal wallpaperChanged(string path, int type)
    signal modelUpdateDone
    signal thumbnailReady(string path)
    signal thumbnailFailed(string source)

    // What the selector browses: "image", "video" or "both". A plain string
    // rather than a second enum — QML only exposes one enum per type here.
    function getModel(filter) {
        if (Config.wallpaper.selectorSort === "random") {
            return shuffledWallpapersModel;
        } else if (filter === "video") {
            return videoWallpapersModel;
        } else if (filter === "both") {
            return bothWallpapersModel;
        } else {
            return imageWallpapersModel;
        }
    }

    function requestModelUpdate(filter) {
        if (filter !== "image") {
            videoLister.running = true;
        }
    }

    function toType(str) {
        if (str === "image") {
            return WallpaperService.Type.Image;
        } else if (str === "mpvpaper") {
            return WallpaperService.Type.Mpvpaper;
        } else {
            return undefined;
        }
    }

    function typeToString(type) {
        if (type === WallpaperService.Type.Image) {
            return "image";
        } else if (type === WallpaperService.Type.Mpvpaper) {
            return "mpvpaper";
        } else {
            return undefined;
        }
    }

    function setWallpaperToCurrent() {
        const type = toType(Config.wallpaper.type);
        if (type === undefined) {
            return;
        }

        setWallpaper(Config.wallpaper.current, type);
    }

    // What is actually on screen. Every write to wallpaper.json reloads the
    // file and calls setWallpaperToCurrent(), so without this a write that only
    // touched an unrelated key (the selector filter) would re-run the color
    // generators and the wallpaper transition.
    property string _applied: ""
    property int _appliedType: -1

    function setWallpaper(wallpaper, type) {
        if (!wallpaper || type === undefined) {
            return;
        }

        if (wallpaper === root._applied && type === root._appliedType) {
            return;
        }

        root._applied = wallpaper;
        root._appliedType = type;
        console.log("[wallpaper] Setting wallpaper to", wallpaper);
        Config.wallpaper.current = wallpaper;
        Config.wallpaper.type = typeToString(type);
        root.wallpaperChanged(wallpaper, type);

        if (type === WallpaperService.Type.Image) {
            generateThumbnail(wallpaper, type);
            generateColors(wallpaper);
        } else {
            root._colorsWaitForThumbnail = true;
            generateThumbnail(wallpaper, type);
        }
    }

    // Each backend is a no-op unless Config.theme.colorscheme names it.
    function generateColors(wallpaper) {
        IrisService.generate(wallpaper);
        MatugenService.generate(wallpaper);
    }

    // What the generators read: the wallpaper itself, or a video's thumbnail.
    function colorSource() {
        if (toType(Config.wallpaper.type) === WallpaperService.Type.Mpvpaper) {
            return root._thumbnailSource ? root.thumbnailPath : "";
        }

        return Config.wallpaper.current;
    }

    // Picking a generator theme regenerates from the wallpaper already set,
    // instead of waiting for the next wallpaper change.
    Connections {
        target: Config.theme

        function onColorschemeChanged() {
            root.generateColors(root.colorSource());
        }
    }

    onThumbnailReady: path => {
        if (root._colorsWaitForThumbnail) {
            root._colorsWaitForThumbnail = false;
            generateColors(path);
        }
    }

    onThumbnailFailed: {
        root._colorsWaitForThumbnail = false;
    }

    function generateThumbnail(wallpaper, type) {
        if (!wallpaper || type !== WallpaperService.Type.Mpvpaper) {
            return;
        }

        const source = expandPath(wallpaper.toString()).replace(/^file:\/\//, "");

        if (source === root._thumbnailSource) {
            root.thumbnailReady(root.thumbnailPath);
            return;
        }

        if (thumbnailer.running) {
            root._pendingThumbnail = source;
            return;
        }

        root._pendingThumbnail = "";
        _startThumbnailer(source, "1");
    }

    function _startThumbnailer(source, seek) {
        root.generatingThumbnail = true;
        thumbnailer.source = source;
        thumbnailer.seek = seek;
        thumbnailer.running = true;
    }

    // Returns { path, type } — in Both mode the type comes from the row itself.
    function getWallpaper(index, filter) {
        if (index < 0) {
            return undefined;
        }

        // Only the image list is a FolderListModel, which is read by role name.
        const model = getModel(filter);
        if (model === imageWallpapersModel) {
            const path = model.get(index, "filePath");
            return path ? {
                path: path,
                type: WallpaperService.Type.Image
            } : undefined;
        }

        const row = model.get(index);
        if (!row) {
            return undefined;
        }

        return {
            path: row.filePath,
            type: filter === "video" ? WallpaperService.Type.Mpvpaper : row.type
        };
    }

    function expandPath(path) {
        return path.replace(/\$\{?(\w+)\}?/g, function (match, varName) {
            var value = Quickshell.env(varName);
            return value !== null ? value : match;
        });
    }

    FolderListModel {
        id: imageWallpapersModel
        folder: "file://" + root.expandPath(Config.wallpaper.staticWallpaperFolder)
        nameFilters: ["*.jpg", "*.png"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Time
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                root._rebuildBoth();
                Qt.callLater(root.modelUpdateDone);
            }
        }
    }

    ListModel {
        id: videoWallpapersModel
    }

    // Images then videos; the video helper carries no mtime, so the two lists
    // are concatenated rather than sorted together.
    ListModel {
        id: bothWallpapersModel
    }

    // Whatever the filter browses, in a random order. Filled on demand so the
    // ordered models stay the source of truth and nothing is shuffled twice.
    ListModel {
        id: shuffledWallpapersModel
    }

    function _rows(filter) {
        const rows = [];

        if (filter !== "video") {
            for (let i = 0; i < imageWallpapersModel.count; i++) {
                rows.push({
                    preview: "",
                    filePath: imageWallpapersModel.get(i, "filePath"),
                    type: WallpaperService.Type.Image
                });
            }
        }

        if (filter !== "image") {
            for (let i = 0; i < videoWallpapersModel.count; i++) {
                const row = videoWallpapersModel.get(i);
                rows.push({
                    preview: row.preview,
                    filePath: row.filePath,
                    type: WallpaperService.Type.Mpvpaper
                });
            }
        }

        return rows;
    }

    function _reshuffle() {
        shuffledWallpapersModel.clear();
        if (Config.wallpaper.selectorSort !== "random") {
            return;
        }

        const rows = _rows(Config.wallpaper.selectorFilter);
        for (let i = rows.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const swap = rows[i];
            rows[i] = rows[j];
            rows[j] = swap;
        }

        for (let i = 0; i < rows.length; i++) {
            shuffledWallpapersModel.append(rows[i]);
        }
    }

    // A shuffle is only redrawn when asked for, not on every model change, so
    // the order under the cursor stays put while browsing.
    Connections {
        target: Config.wallpaper

        function onSelectorSortChanged() {
            root._reshuffle();
            Qt.callLater(root.modelUpdateDone);
        }

        function onSelectorFilterChanged() {
            root._reshuffle();
            Qt.callLater(root.modelUpdateDone);
        }
    }

    function _rebuildBoth() {
        bothWallpapersModel.clear();

        for (let i = 0; i < imageWallpapersModel.count; i++) {
            bothWallpapersModel.append({
                preview: "",
                filePath: imageWallpapersModel.get(i, "filePath"),
                type: WallpaperService.Type.Image
            });
        }

        for (let i = 0; i < videoWallpapersModel.count; i++) {
            const row = videoWallpapersModel.get(i);
            bothWallpapersModel.append({
                preview: row.preview,
                filePath: row.filePath,
                type: WallpaperService.Type.Mpvpaper
            });
        }

        root._reshuffle();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "fullscreen") {
                root.paused = event.data === "1";
            }
        }

        function onFocusedWorkspaceChanged() {
            if (Hyprland.focusedWorkspace?.toplevels.values.length === 0) {
                root.paused = false;
            }
        }

        function onActiveToplevelChanged() {
            const wlToplevel = Hyprland.activeToplevel?.wayland;
            root.paused = wlToplevel?.maximized || wlToplevel?.fullscreen || false;
        }
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
                    root._rebuildBoth();
                    Qt.callLater(root.modelUpdateDone);
                } catch (e) {
                    console.log("[mpvpaper] Failed to parse video wallpapers:", e);
                }
            }
        }
    }

    Process {
        id: thumbnailer
        running: false

        property string source: ""
        property string seek: "1"

        command: ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-ss", seek, "-i", source, "-frames:v", "1", "-update", "1", "-q:v", "3", "-vf", "scale=640:-2", root.thumbnailPath]

        stderr: StdioCollector {
            id: thumbnailerErr
        }

        onExited: exitCode => {
            const finished = source;

            if (exitCode !== 0 && seek !== "0") {
                // A pre-input `-ss 1` yields no frame on videos shorter than a
                // second, so fall back to the very first frame once.
                Qt.callLater(root._startThumbnailer, finished, "0");
                return;
            }

            if (exitCode === 0) {
                root._thumbnailSource = finished;
                console.log("[wallpaper] Generated thumbnail for", finished);
            } else {
                console.log("[wallpaper] Failed to generate thumbnail for", finished, "-", thumbnailerErr.text.trim());
            }

            root.generatingThumbnail = false;

            // A newer wallpaper was picked while ffmpeg ran — go straight to it
            // instead of announcing a thumbnail that is already stale.
            const pending = root._pendingThumbnail;
            root._pendingThumbnail = "";
            if (pending && pending !== root._thumbnailSource) {
                Qt.callLater(root._startThumbnailer, pending, "1");
                return;
            }

            if (exitCode === 0) {
                root.thumbnailReady(root.thumbnailPath);
            } else {
                root.thumbnailFailed(finished);
            }
        }
    }

}
