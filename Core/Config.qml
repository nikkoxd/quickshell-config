pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Services

Singleton {
    id: root
    property var island: islandLoader.adapter
    property var visualizer: visualizerLoader.adapter
    property var launcher: launcherLoader.adapter
    property var theme: themeLoader.adapter
    property var wallpaper: wallpaperLoader.adapter
    property var recorder: recorderLoader.adapter
    property var iris: irisLoader.adapter
    property var dock: dockLoader.adapter
    property var colorscheme: colorschemeLoader.adapter

    Connections {
        target: themeLoader.adapter
        function onColorschemeChanged() {
            colorschemeLoader.updatePath();
        }
    }

    FileView {
        id: islandLoader
        path: Qt.resolvedUrl("../Config/island.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property int height: 35
            property int margins: 10
            property int padding: 40
            property int radius: 20
            property string keepassVault: ""
        }
    }

    FileView {
        id: launcherLoader
        path: Qt.resolvedUrl("../Config/launcher.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property bool showResultsWithEmptyQuery: true
        }
    }

    FileView {
        id: visualizerLoader
        path: Qt.resolvedUrl("../Config/visualizer.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property bool displayVisualizer: true
            property real visualizerHeight: 1
            property real topOpacity: 0.8
            property real bottomOpacity: 0
        }
    }

    FileView {
        id: themeLoader
        path: Qt.resolvedUrl("../Config/theme.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property string colorscheme: "Moonfly"
            property string fontFamily: "Google Sans"
            property string fontWeight: "Regular"
            property int fontSize: 14
        }
    }

    FileView {
        id: wallpaperLoader
        path: Qt.resolvedUrl("../Config/wallpaper.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            Qt.callLater(() => {
                WallpaperService.setWallpaperToCurrent();
            });
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property string output: "ALL"
            property string current
            property string type: "image"
            property string staticWallpaperFolder: "$HOME/Pictures/Wallpapers/"
        }
    }

    FileView {
        id: recorderLoader
        path: Qt.resolvedUrl("../Config/recorder.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            Qt.callLater(() => {
                if (root.recorder.replayAutostart) {
                    RecordingService.toggleReplay();
                }
            })
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property string recordingsFolder: "$HOME/Videos/"
            property string replaysFolder: "$HOME/Videos/Replays/"
            property string screenshotsFolder: "$HOME/Pictures/Screenshots/"
            property bool replayAutostart: false
            property bool recordingAudio: true
            property int recordingFramerate: 60
            property int replayDuration: 60
        }
    }

    FileView {
        id: irisLoader
        path: Qt.resolvedUrl("../Config/iris.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property bool enabled: true
            property bool autoMode: true
            property bool dark: true
            property string after: ""
        }
    }

    FileView {
        id: dockLoader
        path: Qt.resolvedUrl("../Config/dock.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property bool enabled: true
            property bool onlyOnHover: true
            property bool coloredIcons: true
            property int hotzoneHeight: 40
            property int iconSize: 40
            property int spacing: 8
            property list<string> pinned: []
        }
    }

    FileView {
        id: colorschemeLoader
        path: Qt.resolvedUrl("../Themes/Moonfly.json")
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        function updatePath() {
            var scheme = themeLoader.adapter.colorscheme || "Moonfly";
            var newPath = Qt.resolvedUrl("../Themes/" + scheme + ".json");
            if (path !== newPath) {
                path = newPath;
                reload();
            }
        }

        adapter: JsonAdapter {
            property string bg: "#080808"
            property string surface: "#313131"
            property string fg: "#dadada"
            property string dim: "#555555"
            property string accent: "#bfad9e"
            property string accentAlt: "#5f4d3e"
        }
    }
}
