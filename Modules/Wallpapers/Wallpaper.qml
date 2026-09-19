pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia
import Quickshell.Hyprland
import qs.Core
import qs.Services

PanelWindow {
    id: root
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background

    property int frontSlot: 0
    property bool transitionRunning: false

    // Which inputs drive the pan: workspace | cursor | both.
    readonly property bool workspaceParallax: Config.wallpaper.parallax && Config.wallpaper.parallaxSource !== "cursor"
    readonly property bool cursorParallax: Config.wallpaper.parallax && Config.wallpaper.parallaxSource !== "workspace"

    // Overscan each input pans across, as a fraction of the screen size. Zero
    // travel leaves that layer exactly screen sized, so a disabled input costs
    // nothing. The cursor pans both axes; workspaces only run sideways.
    readonly property real workspaceTravel: root.workspaceParallax ? Math.max(0, Config.wallpaper.parallaxAmount) : 0
    readonly property real cursorTravel: root.cursorParallax ? Math.max(0, Config.wallpaper.parallaxMouseAmount) : 0

    // The poller behind CursorService is only worth running while the wallpaper
    // actually follows the pointer.
    onCursorParallaxChanged: {
        if (root.cursorParallax)
            CursorService.subscribe();
        else
            CursorService.unsubscribe();
    }

    // Where the pointer sits on this monitor, 0..1 on each axis. Hyprland
    // reports it in layout coordinates, so the monitor's own origin comes off
    // first.
    readonly property var parallaxMonitor: Hyprland.monitorFor(root.screen) ?? Hyprland.focusedMonitor

    readonly property real cursorFractionX: {
        if (root.cursorTravel <= 0 || root.width <= 0)
            return 0.5;
        return Math.max(0, Math.min(1, (CursorService.x - (root.parallaxMonitor?.x ?? 0)) / root.width));
    }

    readonly property real cursorFractionY: {
        if (root.cursorTravel <= 0 || root.height <= 0)
            return 0.5;
        return Math.max(0, Math.min(1, (CursorService.y - (root.parallaxMonitor?.y ?? 0)) / root.height));
    }

    // Where the focused workspace sits in the run of workspaces, 0..1. The
    // leftmost workspace shows the left edge of the wallpaper, the rightmost
    // the right edge.
    readonly property real parallaxFraction: {
        if (root.workspaceTravel <= 0)
            return 0;

        const focused = Hyprland.focusedWorkspace;
        if (!focused)
            return 0;

        const span = Config.wallpaper.parallaxWorkspaces;
        if (span > 0) {
            if (span < 2)
                return 0;
            return Math.max(0, Math.min(1, (focused.id - 1) / (span - 1)));
        }

        // Auto: spread over the workspaces that exist right now. Special
        // workspaces carry negative ids and would pin the pan to one end, so
        // they are left out and simply hold the position.
        const ids = (Hyprland.workspaces?.values ?? []).map(workspace => workspace.id).filter(id => id > 0).sort((a, b) => a - b);
        const index = ids.indexOf(focused.id);
        if (index === -1 || ids.length < 2)
            return 0;

        return index / (ids.length - 1);
    }

    Component.onCompleted: {
        // onCursorParallaxChanged never fires for the value the property loads
        // with, so the first subscription is taken by hand.
        if (root.cursorParallax)
            CursorService.subscribe();

        root.setWallpaper(Config.wallpaper.current, WallpaperService.toType(Config.wallpaper.type));
    }

    // Quickshell keeps singletons across a reload that replaces this window, so
    // a subscription that is never handed back would leave the poller running
    // with nobody reading it.
    Component.onDestruction: {
        if (root.cursorParallax)
            CursorService.unsubscribe();
    }

    Connections {
        target: WallpaperService
        function onWallpaperChanged(path, type) {
            root.setWallpaper(path, type);
        }
    }

    function setWallpaper(url, type) {
        if (!url || transitionRunning) return;
        var back = frontSlot === 0 ? slotB : slotA;
        transitionRunning = true;
        back.isVideo = type === WallpaperService.Type.Mpvpaper;
        back.wallpaper = url;
        waiter.target = back;
        // The back slot may already be ready (e.g. a cached image loads
        // synchronously), in which case readyChanged never fires — so kick
        // the transition off immediately here.
        if (back.ready)
            startTransition();
    }

    function startTransition() {
        if (anim.running) return;
        waiter.target = null;
        effect.seed = Math.random() * 1000.0;
        // Picked here rather than bound to the config so the random roll happens
        // once per wallpaper change and can never swap the shader mid-animation.
        effect.fragmentShader = Qt.resolvedUrl("./Shaders/" + pickTransition() + ".frag.qsb");
        anim.start();
    }

    function pickTransition() {
        var all = WallpaperService.transitions;
        if (Config.wallpaper.randomTransition)
            return all[Math.floor(Math.random() * all.length)];
        var name = Config.wallpaper.transition;
        return all.indexOf(name) === -1 ? "doom" : name;
    }

    anchors {
        top: true
        left: true
        bottom: true
        right: true
    }

    component Slot: Item {
        id: slot
        anchors.fill: parent
        layer.enabled: true

        property url wallpaper
        property bool isVideo: false
        readonly property bool ready: loader.item ? loader.item.ready : false

        // Fed from the outside, so the slot stays a self-contained component.
        // Each pan is a 0..1 position within its own overscan.
        property real workspaceOverscan: 0
        property real workspacePan: 0
        property real cursorOverscan: 0
        property real cursorPanX: 0.5
        property real cursorPanY: 0.5

        // Two nested oversized layers rather than one: the workspace pan is a
        // long slide between two resting points while the cursor pan chases the
        // pointer, so they need their own durations. Each is wider than what it
        // sits in and slides within it; the slot is a layer, so whatever hangs
        // over its edges is cropped by the layer texture.
        Item {
            id: workspaceLayer
            width: parent.width * (1 + slot.workspaceOverscan)
            height: parent.height
            x: -slot.workspacePan * (width - parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: Config.wallpaper.parallaxDuration
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                id: loader
                width: parent.width * (1 + slot.cursorOverscan)
                height: parent.height * (1 + slot.cursorOverscan)
                x: -slot.cursorPanX * (width - parent.width)
                y: -slot.cursorPanY * (height - parent.height)
                sourceComponent: slot.isVideo ? videoComp : imageComp

                Behavior on x {
                    NumberAnimation {
                        duration: Config.wallpaper.parallaxMouseDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: Config.wallpaper.parallaxMouseDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Component {
            id: imageComp
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: slot.wallpaper
                readonly property bool ready: status === Image.Ready
            }
        }

        Component {
            id: videoComp
            VideoOutput {
                id: vo
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                // The player only reaches BufferedMedia while actively
                // playing; a loaded, decodable video with a frame is enough
                // to reveal the slot.
                readonly property bool ready: player.hasVideo
                    && player.mediaStatus >= MediaPlayer.LoadedMedia
                    && player.mediaStatus !== MediaPlayer.InvalidMedia

                MediaPlayer {
                    id: player
                    source: slot.wallpaper
                    videoOutput: vo
                    loops: MediaPlayer.Infinite
                    audioOutput: null

                    // play() is a no-op until the media is loaded (FFmpeg
                    // backend), so drive playback off mediaStatus rather than
                    // Component.onCompleted.
                    function updatePlayback() {
                        if (mediaStatus < MediaPlayer.LoadedMedia)
                            return;
                        if (WallpaperService.paused)
                            pause();
                        else
                            play();
                    }
                    onMediaStatusChanged: updatePlayback()
                    onErrorOccurred: (err, str) => console.log("[video] error", err, str)
                }

                Connections {
                    target: WallpaperService
                    function onPausedChanged() { player.updatePlayback(); }
                }
            }
        }
    }

    Slot {
        id: slotA
        workspaceOverscan: root.workspaceTravel
        workspacePan: root.parallaxFraction
        cursorOverscan: root.cursorTravel
        cursorPanX: root.cursorFractionX
        cursorPanY: root.cursorFractionY
    }

    Slot {
        id: slotB
        workspaceOverscan: root.workspaceTravel
        workspacePan: root.parallaxFraction
        cursorOverscan: root.cursorTravel
        cursorPanX: root.cursorFractionX
        cursorPanY: root.cursorFractionY
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent

        property variant source: root.frontSlot === 0 ? slotA : slotB
        property variant dest:   root.frontSlot === 0 ? slotB : slotA

        // The union of every transition shader's uniforms: a shader ignores the
        // properties it does not declare, but a uniform with no matching
        // property warns and reads zero.
        property real progress: 0.0
        property real sectionWidth: 0.02
        property real maxOffset: 0.75
        property real seed: 0.0
        property real aspect: width / height
        property real waveAmplitude: 0.04
        property real waveCount: 3.0
    }

    NumberAnimation {
        id: anim
        target: effect
        property: "progress"
        from: 0
        to: 1
        duration: 1500
        onFinished: {
            root.frontSlot = root.frontSlot === 0 ? 1 : 0;
            effect.progress = 0;
            var old = root.frontSlot === 0 ? slotB : slotA;
            old.wallpaper = "";
            root.transitionRunning = false;
        }
    }

    Connections {
        id: waiter
        target: null
        function onReadyChanged() {
            if (waiter.target && waiter.target.ready)
                root.startTransition();
        }
    }
}
