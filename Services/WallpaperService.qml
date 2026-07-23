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
        if (paused) {
            console.log("[mpvpaper] Pausing playback");
        } else {
            console.log("[mpvpaper] Resuming playback");
        }
        mpvpaperControl.command = ["sh", "-c", `echo '{ "command": ["set_property", "pause", ${paused}] }' | socat - /tmp/mpvpaper-socket`]
        mpvpaperControl.running = true;
    }

    enum Type {
        Image,
        Mpvpaper
    }

    function startAwwwDaemon() {
        console.log("[awww] Starting awww-daemon");
        awwwDaemon.running = true;
    }

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
        Config.wallpaper.current = wallpaper;
        Config.wallpaper.type = typeToString(type);
        if (type === WallpaperService.Type.Image) {
            console.log("[awww] Setting wallpaper to", wallpaper);
            mpvpaperSetter.running = false;
            awwwSetter.command = ["awww", "img", wallpaper, "-t", "random", "--transition-fps", "60"];
            awwwSetter.running = true;
        } else if (type === WallpaperService.Type.Mpvpaper) {
            console.log("[mpvpaper] Setting wallpaper to", wallpaper);
            mpvpaperSetter.running = false;
            mpvpaperSetter.command = ["mpvpaper", Config.wallpaper.output, wallpaper,
                                      "-o", "no-audio loop-file=inf input-ipc-server=/tmp/mpvpaper-socket"];
            mpvpaperSetter.running = true;
        }
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

    Process {
        id: awwwDaemon
        command: ["awww-daemon"]
        onExited: (exitCode, exitStatus) => {
            console.log("[awww] Daemon exited with code:", exitCode);
        }
    }

    Process {
        id: awwwSetter
        running: false
        onExited: (exitCode, exitStatus) => {
            console.log("[awww] Exited with code:", exitCode);
        }
    }

    Process {
        id: mpvpaperSetter
        running: false
        onExited: (exitCode, exitStatus) => {
            console.log("[mpvpaper] Exited with code:", exitCode);
        }
    }

    Process {
        id: mpvpaperControl
    }
}
