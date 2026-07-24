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

    enum Type {
        Image,
        Mpvpaper
    }

    signal wallpaperChanged(string path, int type)

    function getModel(type) {
        if (type === WallpaperService.Type.Image) {
            return imageWallpapersModel;
        } else {
            return videoWallpapersModel;
        }
    }

    signal modelUpdateDone
    function requestModelUpdate(type) {
        if (type === WallpaperService.Type.Image) {
            return;
        } else {
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

    function setWallpaper(wallpaper, type) {
        if (!wallpaper || type === undefined) {
            return;
        }
        console.log("[wallpaper] Setting wallpaper to", wallpaper);
        Config.wallpaper.current = wallpaper;
        Config.wallpaper.type = typeToString(type);
        root.wallpaperChanged(wallpaper, type);
    }

    function getWallpaperPath(index, type) {
        if (type === WallpaperService.Type.Image) {
            return imageWallpapersModel.get(index, "filePath");
        } else {
            return videoWallpapersModel.get(index).filePath;
        }
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
                Qt.callLater(root.modelUpdateDone);
            }
        }
    }

    ListModel {
        id: videoWallpapersModel
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
                    Qt.callLater(root.modelUpdateDone);
                } catch (e) {
                    console.log("[mpvpaper] Failed to parse video wallpapers:", e);
                }
            }
        }
    }

}
