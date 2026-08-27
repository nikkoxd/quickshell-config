pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Core

Singleton {
    id: root

    // Workshop item folder of the scene that should be on screen, "" for none.
    property string current: ""
    readonly property bool active: current !== "" && root._ready

    // wallpiperctl can only talk to a daemon whose renderer is up. Sending a
    // command before then does not fail, it *blocks forever*, which would wedge
    // the queue below — so anything requested early is parked until ready.
    property bool _ready: false
    property var _queue: []
    property bool _starting: false
    // Wallpaper Engine can take a while to answer even after the renderer is
    // tracked, so a failed command is worth another try or two.
    property int _retries: 0
    readonly property int _maxRetries: 5

    function start(sceneDir) {
        if (!sceneDir) {
            stop();
            return;
        }

        if (sceneDir === root.current && root.active) {
            return;
        }

        root.current = sceneDir;
        root._apply(sceneDir);
    }

    function stop() {
        if (root.current === "") {
            return;
        }

        root.current = "";
        // The daemon is left up: it costs a Proton process to start, and a
        // stopped engine draws nothing.
        root._control(["stop"]);
    }

    function _apply(sceneDir) {
        const id = root.sceneId(sceneDir);
        if (!id) {
            console.log("[scene] Could not derive a Workshop ID from", sceneDir);
            return;
        }

        root._ensureDaemon();

        // `set` with no monitor argument covers every output; per-monitor needs
        // one call each.
        const monitors = root.targetMonitors();
        if (monitors === undefined) {
            root._control(["set", id]);
        } else if (monitors.length === 0) {
            console.log("[scene] No target monitor for", id);
            return;
        } else {
            for (const index of monitors) {
                root._control(["set", id, String(index)]);
            }
        }

        root._applyAudio();
    }

    function _applyAudio() {
        if (Config.wallpaper.sceneMuted) {
            root._control(["mute"]);
        } else {
            root._control(["unmute"]);
            root._control(["volume", String(Config.wallpaper.sceneVolume)]);
        }
    }

    // Which outputs to draw on. Config.wallpaper.output is a plain string; the
    // sentinel "ALL" means every connected screen, which is `undefined` here
    // because wallpiper expresses it by omitting the argument entirely.
    // Otherwise wallpiper wants 0-indexed monitor numbers, not names.
    function targetMonitors() {
        const configured = (Config.wallpaper.output || "ALL").trim();
        if (configured === "" || configured.toUpperCase() === "ALL") {
            return undefined;
        }

        const names = Quickshell.screens.map(screen => screen.name);
        return configured.split(",").map(name => names.indexOf(name.trim())).filter(index => index >= 0);
    }

    // The Workshop ID is the item folder's name, which is what `set` wants.
    function sceneId(sceneDir) {
        const trimmed = sceneDir.toString().replace(/^file:\/\//, "").replace(/\/+$/, "");
        return trimmed.slice(trimmed.lastIndexOf("/") + 1);
    }

    // wallpiper writes the tracked renderer's pid here once Wallpaper Engine is
    // actually up; the file exists but is empty before that. It is the one
    // readiness signal that works for a daemon this shell did not start.
    readonly property string _rendererPidFile: (Quickshell.env("WALLPIPER_TEMP_DIR") || "/tmp/wallpiper") + "/wallpiper-renderer-pid"

    // A daemon left behind by an earlier shell is reused rather than replaced,
    // both because a second one cannot bind the control socket and because
    // restarting it means restarting Wallpaper Engine under Proton.
    function _ensureDaemon() {
        if (root._ready || root._starting) {
            return;
        }

        root._starting = true;
        daemon.running = true;
        readyPoll.restart();
    }

    function _control(args) {
        root._queue = root._queue.concat([args]);
        root._drain();
    }

    // wallpiperctl is one process per command, so commands are run one after
    // another rather than concurrently.
    function _drain() {
        if (control.running || root._queue.length === 0 || !root._ready) {
            return;
        }

        const args = root._queue[0];
        root._queue = root._queue.slice(1);
        control.command = ["wallpiperctl"].concat(args);
        control.running = true;
    }

    // The scene must come down with the shell, or a surface owned by another
    // process outlives it and sits over the next wallpaper. Only the scene,
    // though — see the note above on why the daemon stays up.
    Component.onDestruction: {
        if (root.current !== "") {
            Quickshell.execDetached(["wallpiperctl", "stop"]);
        }
    }

    // Monitor indices are positional, so adding or removing an output can move
    // the scene to the wrong screen.
    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (root.active) {
                root._apply(root.current);
            }
        }
    }

    Connections {
        target: Config.wallpaper

        function onSceneMutedChanged() {
            if (root.active) {
                root._applyAudio();
            }
        }

        function onSceneVolumeChanged() {
            if (root.active) {
                root._applyAudio();
            }
        }
    }

    Process {
        id: daemon
        running: false
        // `pgrep` first so an already-running daemon is adopted, `setsid` and
        // the log redirect so the one this shell starts survives it with no
        // pipe left pointing at a dead process. Its own output would otherwise
        // be lost entirely, hence the log file.
        command: ["sh", "-c", "pgrep -x wallpiperd > /dev/null || setsid wallpiperd >> \"${WALLPIPER_TEMP_DIR:-/tmp}/wallpiperd.log\" 2>&1 < /dev/null &"]
        // WALLPIPER_PORTAL is required and has no default. A session that
        // already exports one wins, since only it knows what compositor it is.
        environment: ({
                "WALLPIPER_PORTAL": Quickshell.env("WALLPIPER_PORTAL") || "hyprland"
            })

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("[scene] Could not start wallpiperd:", exitCode);
                root._starting = false;
                readyPoll.stop();
            }
        }
    }

    // Wallpaper Engine comes up under Proton, which takes tens of seconds on a
    // cold start, and a `wallpiperctl` sent before it answers never returns —
    // so readiness is polled rather than assumed.
    Timer {
        id: readyPoll
        interval: 1000
        repeat: true
        triggeredOnStart: true
        property int elapsed: 0
        readonly property int limit: 120

        onRunningChanged: if (running) elapsed = 0

        onTriggered: {
            if (rendererPid.running) {
                return;
            }

            elapsed += 1;
            if (elapsed > limit) {
                console.log("[scene] Wallpaper Engine did not come up in", limit, "s — see wallpiperd.log in WALLPIPER_TEMP_DIR");
                root._starting = false;
                stop();
                return;
            }

            rendererPid.running = true;
        }
    }

    // Non-empty means wallpiper is tracking a live renderer.
    Process {
        id: rendererPid
        running: false
        command: ["test", "-s", root._rendererPidFile]

        onExited: exitCode => {
            if (exitCode !== 0 || root._ready) {
                return;
            }

            readyPoll.stop();
            root._starting = false;
            root._ready = true;
            root._drain();
        }
    }

    // Wallpaper Engine can die on its own, and a scene that is no longer drawn
    // must not keep the shell's own wallpaper window hidden behind an empty
    // wallpiper surface.
    Timer {
        id: livenessPoll
        interval: 5000
        repeat: true
        running: root._ready
        onTriggered: if (!liveness.running) liveness.running = true
    }

    Process {
        id: liveness
        running: false
        command: ["test", "-s", root._rendererPidFile]

        onExited: exitCode => {
            if (exitCode === 0 || !root._ready) {
                return;
            }

            console.log("[scene] Wallpaper Engine is gone; dropping the scene");
            root._ready = false;
            root._queue = [];
            root.current = "";
        }
    }

    // wallpiperctl also fails outright for a few seconds after the renderer
    // first appears, while Wallpaper Engine is still finishing its own startup.
    Timer {
        id: retry
        interval: 2000
        onTriggered: root._drain()
    }

    Process {
        id: control
        running: false

        stderr: StdioCollector {
            id: controlErr
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                root._retries = 0;
                root._drain();
                return;
            }

            const args = control.command.slice(1);
            if (root._retries < root._maxRetries) {
                root._retries++;
                root._queue = [args].concat(root._queue);
                retry.restart();
                return;
            }

            console.log("[scene] wallpiperctl", args.join(" "), "failed", exitCode, "-", controlErr.text.trim());
            root._retries = 0;
            // The daemon or its renderer is gone rather than slow, so the next
            // scene has to go back through startup instead of firing commands
            // at nothing.
            root._ready = false;
            root._queue = [];
        }
    }
}
