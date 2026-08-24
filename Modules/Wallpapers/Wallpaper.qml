pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia
import qs.Core
import qs.Services

PanelWindow {
    id: root
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background

    property int frontSlot: 0
    property bool transitionRunning: false

    Component.onCompleted: root.setWallpaper(Config.wallpaper.current,
                                             WallpaperService.toType(Config.wallpaper.type))

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

        Loader {
            id: loader
            anchors.fill: parent
            sourceComponent: slot.isVideo ? videoComp : imageComp
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

    Slot { id: slotA }
    Slot { id: slotB }

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
