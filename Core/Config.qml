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
    property var matugen: matugenLoader.adapter
    property var dock: dockLoader.adapter
    property var colorscheme: colorschemeLoader.adapter

    // Template registry, keyed by template name. Each entry is
    // { enabled, template, output, postHook }; `template` is the file name
    // looked up in Templates/<generator>/ and defaults to the key. `output`
    // and `postHook` may contain {generator} (Iris/Matugen) and {mode}
    // (dark/light). Shaped too freely for a JsonAdapter, so it is parsed by
    // hand. TemplateService is what consumes it.
    property var templates: root.defaultTemplates

    readonly property var defaultTemplates: ({
            ghostty: {
                enabled: true,
                output: "~/.config/ghostty/themes/Island",
                postHook: "pkill -SIGUSR2 ghostty"
            },
            gtk3: {
                enabled: true,
                template: "gtk.css",
                output: "~/.config/gtk-3.0/colors.css",
                postHook: "gsettings set org.gnome.desktop.interface gtk-theme \"\"; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-{mode}"
            },
            gtk4: {
                enabled: true,
                template: "gtk.css",
                output: "~/.config/gtk-4.0/colors.css",
                postHook: "~/.config/quickshell/island/Helpers/gtk-themes-reload.sh"
            },
            emacs: {
                enabled: true,
                template: "emacs.el",
                output: "~/.config/doom/themes/island-theme.el",
                postHook: "emacsclient -e \"(load-theme 'island t)\""
            },
            discord: {
                enabled: true,
                template: "midnight-discord.css",
                output: "~/.config/Vencord/themes/midnight.css",
                postHook: ""
            },
            qt5ct: {
                enabled: true,
                template: "qtct.conf",
                output: "~/.config/qt5ct/colors/island.conf",
                postHook: ""
            },
            qt6ct: {
                enabled: true,
                template: "qtct.conf",
                output: "~/.config/qt6ct/colors/island.conf",
                postHook: ""
            },
            quickshell: {
                enabled: true,
                template: "quickshell.json",
                output: "~/.config/quickshell/island/Themes/{generator}.json",
                postHook: ""
            },
            telegram: {
                enabled: true,
                template: "telegram.tdesktop-theme",
                output: "~/.config/telegram/island.tdesktop-theme",
                postHook: ""
            }
        })

    function saveTemplates(entries) {
        root.templates = entries;
        templatesLoader.setText(JSON.stringify(entries, null, 4) + "\n");
    }

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
            property int hoverOpenDelay: 100
            property int hoverCloseDelay: 200
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
            property bool sortByUsage: true
            // When false, custom entries are mixed into the normal app results
            // instead of living behind customEntriesPrefix.
            property bool useCustomEntriesPrefix: true
            property string customEntriesPrefix: ">"
            property string commandPrefix: "%"
            property real usageWeight: 0.5
            property int usageHalfLifeDays: 14
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
            // "background" paints the curve behind every view; "bars" draws a
            // handful of discrete bars inline in the default/lyrics view.
            property string mode: "background"
            property real visualizerHeight: 1
            property real topOpacity: 0.8
            property real bottomOpacity: 0
            property int barCount: 4
            property real barWidth: 3
            property real barMaxHeight: 16
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
            property string selectorFilter: "image" // image | video | scene | both (image+video) | all
            property string staticWallpaperFolder: "$HOME/Pictures/Wallpapers/"
            property string transition: "doom"
            property bool randomTransition: false

            property bool sceneMuted: true
            property int sceneVolume: 50
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
            property bool screenshotSave: true
            property bool screenshotCopy: true
            property bool replayAutostart: false
            property bool recordingAudio: true
            property bool recordingMicrophone: false
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
            property bool autoMode: true
            property bool dark: true
            // Shell commands run in order after iris succeeds.
            // e.g. emacsclient -e "(load-theme 'iris t)"
            property list<string> after: []
        }
    }

    FileView {
        id: matugenLoader
        path: Qt.resolvedUrl("../Config/matugen.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            property bool autoMode: false
            property bool dark: true
            // matugen -t
            property string scheme: "scheme-tonal-spot"
            // matugen --prefer; required, matugen fails without a terminal otherwise
            property string prefer: "saturation"
            // matugen --contrast, -1..1; 0 leaves the flag off
            property real contrast: 0
            // Shell commands run in order after matugen succeeds.
            property list<string> after: []
        }
    }

    FileView {
        id: templatesLoader
        path: Qt.resolvedUrl("../Config/templates.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.templates = JSON.parse(text());
            } catch (e) {
                console.warn("config: could not parse templates.json:", e);
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.saveTemplates(root.defaultTemplates);
            }
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
            property bool showWhenWorkspaceClear: true
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
