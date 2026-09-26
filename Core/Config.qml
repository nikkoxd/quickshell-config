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
    property var widgets: widgetsLoader.adapter
    property var notifications: notificationsLoader.adapter
    property var wallhaven: wallhavenLoader.adapter
    property var colorscheme: colorschemeLoader.adapter

    // Whether the active colorscheme is a light one. Derived from the
    // background rather than a generator's `dark` flag, so a hand-written
    // Themes/<Name>.json is classified too.
    readonly property bool lightTheme: Qt.color(root.colorscheme.bg).hslLightness > 0.5

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
            kde: {
                enabled: true,
                template: "kdeglobals",
                output: "~/.local/share/color-schemes/Island.colors",
                postHook: "~/.config/quickshell/island/Helpers/kde-theme.py --scheme ~/.local/share/color-schemes/Island.colors"
            },
            quickshell: {
                enabled: true,
                template: "quickshell.json",
                output: "~/.config/quickshell/island/Themes/{generator}.json",
                postHook: ""
            },
            // A .tdesktop-theme is a zip, not a rendered file, so the
            // template is only the palette and the hook bundles it with the
            // wallpaper. Pass --solid to drop the wallpaper for a flat fill.
            telegram: {
                enabled: true,
                template: "telegram.tdesktop-palette",
                output: "~/.config/telegram/island.tdesktop-palette",
                postHook: "~/.config/quickshell/island/Helpers/telegram-theme.py --palette ~/.config/telegram/island.tdesktop-palette --output ~/.config/telegram/island.tdesktop-theme"
            }
        })

    // DNS presets offered by the dns view, in the order they are listed. Each
    // entry is { name, ipv4: [...], ipv6: [...] }; a list of objects is shaped
    // wrong for a JsonAdapter, so it is parsed by hand like the templates
    // registry. The DHCP entry is not in here -- DnsService always prepends it.
    property var dns: root.defaultDns

    readonly property var defaultDns: [
        {
            name: "Cloudflare",
            ipv4: ["1.1.1.1", "1.0.0.1"],
            ipv6: ["2606:4700:4700::1111", "2606:4700:4700::1001"]
        },
        {
            name: "Cloudflare (no malware)",
            ipv4: ["1.1.1.2", "1.0.0.2"],
            ipv6: ["2606:4700:4700::1112", "2606:4700:4700::1002"]
        },
        {
            name: "Google",
            ipv4: ["8.8.8.8", "8.8.4.4"],
            ipv6: ["2001:4860:4860::8888", "2001:4860:4860::8844"]
        },
        {
            name: "Quad9",
            ipv4: ["9.9.9.9", "149.112.112.112"],
            ipv6: ["2620:fe::fe", "2620:fe::9"]
        },
        {
            name: "AdGuard",
            ipv4: ["94.140.14.14", "94.140.15.15"],
            ipv6: ["2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff"]
        },
        {
            name: "Mullvad",
            ipv4: ["194.242.2.2"],
            ipv6: ["2a07:e340::2"]
        }
    ]

    function saveDns(servers) {
        root.dns = servers;
        dnsLoader.setText(JSON.stringify(servers, null, 4) + "\n");
    }

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
            // Whether a track that has lyrics may swap the clock for the line
            // being sung on its own. Off leaves the clock alone - useful once
            // the desktop lyrics widget is carrying them instead - but the ipc
            // call and the dashboard toggle still reach them by hand.
            property bool displayLyrics: true
            // Shifts the lyrics timeline against playback, in milliseconds.
            // Positive holds each line back, for lyrics whose stamps run ahead
            // of the recording; negative pulls them forward. Applies to both
            // the line the island shows and the desktop lyrics widget.
            property int lyricsOffset: 0
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
            // Process manager provider: sort field (cpu/memory/name/pid), whether
            // rows are collapsed per command name, and whether other users'
            // processes are listed. The last one is flipped from the list itself.
            property string processSort: "cpu"
            property bool groupProcesses: false
            property bool showSystemProcesses: false
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
            property bool displayArtwork: true
            // "background" paints the curve behind every view; "bars" draws a
            // handful of discrete bars inline in the default/lyrics view.
            property string mode: "background"
            // What cava listens to: "auto" leaves it on its own default input
            // (the sink monitor, so every app at once), "player" follows the
            // active MPRIS player's own PipeWire stream. Any other value is
            // used verbatim as a PipeWire node.name.
            property string source: "auto"
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
            // What the wallpaper selector browses: image | video | both
            property string selectorFilter: "image"
            // The order the selector lists wallpapers in: recent | random
            property string selectorSort: "recent"
            // Which online source the wallpaper browser downloads from.
            property string downloadSource: "wallhaven"
            property string staticWallpaperFolder: "$HOME/Pictures/Wallpapers/"
            property string transition: "doom"
            // Pick a random transition on every wallpaper change instead.
            property bool randomTransition: false
            // Pan the wallpaper behind the desktop instead of pinning it to
            // the screen.
            property bool parallax: false
            // What drives the pan: workspace | cursor | both. The workspace
            // slides it sideways as the focused workspace changes; the cursor
            // drifts it on both axes as the pointer moves.
            property string parallaxSource: "workspace"
            // How much wider than the screen the wallpaper is drawn for the
            // workspace pan, as a fraction of the screen width. That overscan
            // is what gets panned across, so it doubles as the strength.
            property real parallaxAmount: 0.15
            // How many workspaces the pan is spread over. 0 spreads it over
            // whatever workspaces exist at the time, so the step size changes
            // as they come and go.
            property int parallaxWorkspaces: 10
            property int parallaxDuration: 400
            // The same, for the cursor pan — a far smaller drift, and quick
            // enough to read as following the pointer rather than catching up
            // with it.
            property real parallaxMouseAmount: 0.04
            property int parallaxMouseDuration: 150
        }
    }

    FileView {
        id: wallhavenLoader
        path: Qt.resolvedUrl("../Config/wallhaven.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            // Three bits each, in the order Wallhaven's API takes them:
            // categories is general/anime/people, purity is sfw/sketchy/nsfw.
            property string categories: "111"
            property string purity: "100"
            // date_added | relevance | random | views | favorites | toplist
            property string sorting: "date_added"
            // Aspect ratio filter: landscape, portrait or an exact ratio like
            // 16x9. Empty for no filter.
            property string ratios: ""
            // Only read for the toplist sorting.
            property string topRange: "1M"
            // Last search, so reopening the browser lands where it was left.
            property string query: ""
            // Needed for NSFW results, and for a logged-in user's own filters.
            property string apiKey: ""
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
            property bool screenshotFreeze: true
            property bool replayAutostart: false
            property bool recordingAudio: true
            property bool recordingMicrophone: false
            property int recordingFramerate: 60
            property int replayDuration: 60
            property string ocrLanguage: "rus+eng"
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
        id: dnsLoader
        path: Qt.resolvedUrl("../Config/dns.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed)) {
                    root.dns = parsed;
                } else {
                    console.warn("config: dns.json is not a list of servers");
                }
            } catch (e) {
                console.warn("config: could not parse dns.json:", e);
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.saveDns(root.defaultDns);
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
        id: widgetsLoader
        path: Qt.resolvedUrl("../Config/widgets.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            // The lyrics widget: the dashboard's lyrics panel, cut down to a
            // few rows and parked at the bottom of the desktop.
            property bool lyricsEnabled: false
            property int lyricsRows: 3
            property int lyricsWidth: 900
            property int lyricsBottomMargin: 64
            property real lyricsFontScale: 1.8
            // How much bigger the line being sung is drawn than the ones around it.
            property real lyricsActiveScale: 1.15
            property bool lyricsCentered: true
            // Lyrics of a paused track are stale on screen; hide them until
            // playback resumes.
            property bool lyricsOnlyWhilePlaying: true
        }
    }

    FileView {
        id: notificationsLoader
        path: Qt.resolvedUrl("../Config/notifications.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
        adapter: JsonAdapter {
            // Do not disturb: notification popups are suppressed while it is
            // on. Lives here so it survives a reload of the shell.
            property bool doNotDisturb: false
            // Play a sound when a notification arrives. The file is a name
            // inside Sounds/, so the config stays portable across machines.
            property bool sound: false
            property string soundFile: ""
            // Percentage, so the settings page can edit it as a plain number.
            property int soundVolume: 100
            // Apps that chime for themselves. Matched against the app name or
            // the desktop-entry hint; see NotificationService.playsItsOwnSound.
            property list<string> silentApps: []
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
