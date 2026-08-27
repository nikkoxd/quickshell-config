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
        Mpvpaper,
        Scene
    }

    // Available wallpaper transitions. Each name maps to
    // Modules/Wallpapers/Shaders/<name>.frag.qsb.
    readonly property var transitions: ["doom", "diagonal", "diagonalWave", "circleRandom"]

    signal wallpaperChanged(string path, int type)
    signal modelUpdateDone
    signal thumbnailReady(string path)
    signal thumbnailFailed(string source)

    // What the selector browses: "image", "video", "scene", "both"
    // (image+video) or "all". A plain string rather than a second enum — QML
    // only exposes one enum per type here.
    function getModel(filter) {
        if (filter === "video") {
            return videoWallpapersModel;
        } else if (filter === "scene") {
            return sceneWallpapersModel;
        } else if (filter === "all") {
            return allWallpapersModel;
        } else if (filter === "both") {
            return bothWallpapersModel;
        } else {
            return imageWallpapersModel;
        }
    }

    // Both live in the same Workshop folder and come from one run of the
    // helper, so anything that is not purely images needs the lister.
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
        } else if (str === "scene") {
            return WallpaperService.Type.Scene;
        } else {
            return undefined;
        }
    }

    function typeToString(type) {
        if (type === WallpaperService.Type.Image) {
            return "image";
        } else if (type === WallpaperService.Type.Mpvpaper) {
            return "mpvpaper";
        } else if (type === WallpaperService.Type.Scene) {
            return "scene";
        } else {
            return undefined;
        }
    }

    function setWallpaperToCurrent() {
        const type = toType(Config.wallpaper.type);
        if (type === undefined) {
            return;
        }

        // A scene is represented by its preview image everywhere outside the
        // external renderer, and only the helper knows where that preview is.
        if (type === WallpaperService.Type.Scene) {
            requestModelUpdate("scene");
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

        // A scene whose renderer died is still the applied wallpaper but is no
        // longer on screen, so picking it again has to be allowed to relaunch.
        const staleScene = type === WallpaperService.Type.Scene && !SceneWallpaperService.active;

        if (wallpaper === root._applied && type === root._appliedType && !staleScene) {
            return;
        }

        const wasScene = root._appliedType === WallpaperService.Type.Scene;

        root._applied = wallpaper;
        root._appliedType = type;
        console.log("[wallpaper] Setting wallpaper to", wallpaper);
        Config.wallpaper.current = wallpaper;
        Config.wallpaper.type = typeToString(type);
        root.wallpaperChanged(wallpaper, type);

        if (type === WallpaperService.Type.Scene) {
            SceneWallpaperService.start(wallpaper);
        } else if (wasScene) {
            // The scene's layer surface covers the shell's wallpaper window, so
            // it has to come down before an image or video can be seen.
            SceneWallpaperService.stop();
        }

        if (type === WallpaperService.Type.Image) {
            generateThumbnail(wallpaper, type);
            generateColors(wallpaper);
        } else if (type === WallpaperService.Type.Scene) {
            // No frame to grab from a process that renders straight to its own
            // surface — the Workshop preview stands in for the scene.
            const preview = scenePreview(wallpaper);
            if (preview) {
                root._colorsWaitForScene = false;
                generateColors(preview);
            } else {
                root._colorsWaitForScene = true;
            }
        } else {
            root._colorsWaitForThumbnail = true;
            generateThumbnail(wallpaper, type);
        }
    }

    // Workshop item folder -> preview image, filled in by the lister. Scenes
    // are keyed by folder, so this is also how anything that needs to *show* a
    // scene resolves it to something paintable.
    property var _scenePreviews: ({})
    property bool _colorsWaitForScene: false

    function scenePreview(sceneDir) {
        if (!sceneDir) {
            return "";
        }

        return root._scenePreviews[sceneDir.toString().replace(/^file:\/\//, "")] || "";
    }

    // Each backend is a no-op unless Config.theme.colorscheme names it.
    function generateColors(wallpaper) {
        IrisService.generate(wallpaper);
        MatugenService.generate(wallpaper);
    }

    // What the generators read: the wallpaper itself, a video's thumbnail, or a
    // scene's Workshop preview.
    function colorSource() {
        const type = toType(Config.wallpaper.type);

        if (type === WallpaperService.Type.Mpvpaper) {
            return root._thumbnailSource ? root.thumbnailPath : "";
        }

        if (type === WallpaperService.Type.Scene) {
            return scenePreview(Config.wallpaper.current);
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

        // Only the image filter is backed by a FolderListModel, which needs a
        // role name rather than a row. Every other filter is a ListModel.
        if (filter === "image") {
            const path = imageWallpapersModel.get(index, "filePath");
            return path ? {
                path: path,
                type: WallpaperService.Type.Image
            } : undefined;
        }

        const row = getModel(filter).get(index);
        if (!row) {
            return undefined;
        }

        let type = row.type;
        if (filter === "video") {
            type = WallpaperService.Type.Mpvpaper;
        } else if (filter === "scene") {
            type = WallpaperService.Type.Scene;
        }

        return {
            path: row.filePath,
            type: type
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

    ListModel {
        id: sceneWallpapersModel
    }

    // Images, then videos, (then scenes); the Workshop helper carries no mtime,
    // so the lists are concatenated rather than sorted together.
    //
    // "both" predates scenes and still means image+video, so a config written
    // by an older revision keeps browsing what it used to; "all" is the one
    // that includes scenes. They are two models rather than one rebuilt against
    // the current filter, because switching the filter does not itself rebuild.
    ListModel {
        id: bothWallpapersModel
    }

    ListModel {
        id: allWallpapersModel
    }

    function _appendTo(model, source, type) {
        for (let i = 0; i < source.count; i++) {
            const row = source.get(i);
            model.append({
                preview: row.preview,
                filePath: row.filePath,
                type: type
            });
        }
    }

    function _rebuildBoth() {
        bothWallpapersModel.clear();
        allWallpapersModel.clear();

        for (let i = 0; i < imageWallpapersModel.count; i++) {
            const entry = {
                preview: "",
                filePath: imageWallpapersModel.get(i, "filePath"),
                type: WallpaperService.Type.Image
            };
            bothWallpapersModel.append(entry);
            allWallpapersModel.append(entry);
        }

        _appendTo(bothWallpapersModel, videoWallpapersModel, WallpaperService.Type.Mpvpaper);
        _appendTo(allWallpapersModel, videoWallpapersModel, WallpaperService.Type.Mpvpaper);
        _appendTo(allWallpapersModel, sceneWallpapersModel, WallpaperService.Type.Scene);
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
                    sceneWallpapersModel.clear();

                    const previews = {};

                    for (let i = 0; i < data.length; i++) {
                        const item = data[i];
                        const row = {
                            preview: item.preview || "",
                            filePath: item.file
                        };

                        if (item.type === "scene") {
                            sceneWallpapersModel.append(row);
                            previews[item.file] = row.preview;
                        } else {
                            videoWallpapersModel.append(row);
                        }
                    }

                    root._scenePreviews = previews;
                    root._rebuildBoth();

                    // A scene set at startup could not resolve its preview until
                    // this ran, so the generators were left waiting on it.
                    if (root._colorsWaitForScene) {
                        const preview = root.scenePreview(Config.wallpaper.current);
                        if (preview) {
                            root._colorsWaitForScene = false;
                            root.generateColors(preview);
                            root.wallpaperChanged(Config.wallpaper.current, WallpaperService.Type.Scene);
                        }
                    }

                    Qt.callLater(root.modelUpdateDone);
                } catch (e) {
                    console.log("[wallpaper] Failed to parse Workshop wallpapers:", e);
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
