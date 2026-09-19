pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

// Credit: https://github.com/dhrruvsharma/shell/blob/master/quickshell/services/Cava.qml
Singleton {
    id: root
    property int bars: 10
    property var _parseBuffer: new Array(bars)
    property var values: []

    // Tracks the setting through a binding rather than a Connections on the
    // adapter, which has no statically known signals to attach to.
    readonly property string sourceSetting: Config.visualizer.source
    onSourceSettingChanged: root._restartResolve()

    // PipeWire `node.name` cava captures from. Empty means no [input] section
    // at all, so cava picks its own default - the sink monitor, which carries
    // every app on the system mixed together.
    property string targetNode: ""

    // Set while cava is being stopped only so it can come back up on the new
    // target: cava reads its input source once, at startup.
    property bool _relaunch: false

    readonly property var config: {
        const cfg = {
            "general": {
                "bars": root.bars,
                "framerate": 60,
                "autosens": 1,
                "sensitivity": 100,
                "lower_cutoff_freq": 50,
                "higher_cutoff_freq": 10000
            },
            "output": {
                "method": "raw",
                "data_format": "ascii",
                "ascii_max_range": 100,
                "bit_format": "8bit",
                "channels": "mono",
                "mono_option": "average"
            },
            "smoothing": {
                "monstercat": 1,
                "noise_reduction": 70
            }
        };
        if (root.targetNode !== "")
            cfg["input"] = {
                "method": "pipewire",
                "source": root.targetNode
            };
        return cfg;
    }

    onTargetNodeChanged: {
        if (cava.running) {
            root._relaunch = true;
            cava.running = false;
        } else {
            cava.running = true;
        }
    }

    // `Config.visualizer.source` is "auto" (whatever cava captures by default),
    // "player" (follow the active MPRIS player) or a literal PipeWire node name.
    function resolveSource(): void {
        const source = Config.visualizer.source || "auto";
        if (source !== "player") {
            retry.stop();
            root.targetNode = source === "auto" ? "" : source;
            return;
        }
        if (!MprisService.activePlayer) {
            retry.stop();
            root.targetNode = "";
            return;
        }
        if (!nodeQuery.running)
            nodeQuery.running = true;
    }

    function _restartResolve(): void {
        retry.attempts = 0;
        root.resolveSource();
    }

    function _normalize(value: string): string {
        return (value || "").toString().toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    // Names the active player might be known by on the PipeWire side. The bus
    // name is the most reliable of the three (`org.mpris.MediaPlayer2.sonora`),
    // but players are inconsistent about which of them matches their stream.
    function _playerTokens(): var {
        const player = MprisService.activePlayer;
        if (!player)
            return [];
        const dbus = (player.dbusName || "").replace("org.mpris.MediaPlayer2.", "").split(".")[0];
        return [player.identity, player.desktopEntry, dbus].map(root._normalize).filter(token => token.length >= 3);
    }

    function _matchNode(nodes: var): string {
        const tokens = root._playerTokens();
        if (tokens.length === 0)
            return "";
        for (const node of nodes) {
            const fields = [node.node, node.app, node.binary, node.id].map(root._normalize).filter(field => field.length >= 3);
            for (const token of tokens) {
                for (const field of fields) {
                    if (field.indexOf(token) !== -1 || token.indexOf(field) !== -1)
                        return node.node;
                }
            }
        }
        return "";
    }

    Connections {
        target: MprisService
        // A player's PipeWire stream is not tied to the player's lifetime: it
        // appears when audio starts and can go away again while paused, so the
        // target is re-resolved on every one of these.
        function onActivePlayerChanged(): void {
            root._restartResolve();
        }
        function onIsPlayingChanged(): void {
            root._restartResolve();
        }
        function onTrackChanged(): void {
            root._restartResolve();
        }
    }

    // The stream shows up a moment after the player does, so a miss is retried
    // a few times with a growing delay before falling back to system audio.
    Timer {
        id: retry
        property int attempts: 0
        interval: 500 * Math.pow(2, Math.max(0, attempts - 1))
        onTriggered: root.resolveSource()
    }

    Process {
        id: nodeQuery
        command: ["python3", Quickshell.shellPath("Helpers/audio_nodes.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                let nodes = [];
                try {
                    nodes = JSON.parse(text);
                } catch (e) {
                    console.warn("[cava] could not parse audio_nodes.py output:", e);
                }
                const node = root._matchNode(nodes);
                if (node !== "") {
                    retry.stop();
                    root.targetNode = node;
                } else if (retry.attempts < 5) {
                    retry.attempts++;
                    retry.restart();
                } else {
                    root.targetNode = "";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn("[cava]", text.trim());
            }
        }
    }

    Process {
        id: cava
        stdinEnabled: true
        running: true
        command: ["cava", "-p", "/dev/stdin"]
        onStarted: {
            const config = root.config;
            for (const k in config) {
                if (typeof config[k] !== "object") {
                    write(k + "=" + config[k] + "\n");
                    continue;
                }
                write("[" + k + "]\n");
                const obj = config[k];
                for (const k2 in obj) {
                    write(k2 + "=" + obj[k2] + "\n");
                }
            }
            stdinEnabled = false;
            root.values = Array(root.bars).fill(0);
        }
        onExited: {
            root.values = Array(root.bars).fill(0);
            stdinEnabled = true;
            if (root._relaunch) {
                root._relaunch = false;
                running = true;
            }
        }
        stdout: SplitParser {
            onRead: data => {
                const buffer = root._parseBuffer;
                let idx = 0;
                let num = 0;
                for (let i = 0, len = data.length - 1; i < len; i++) {
                    const c = data.charCodeAt(i);
                    if (c === 59) {
                        buffer[idx++] = num * 0.01;
                        num = 0;
                    } else if (c >= 48 && c <= 57) {
                        num = num * 10 + (c - 48);
                    }
                }
                if (num > 0 || idx < root.bars)
                    buffer[idx++] = num * 0.01;

                root.values = buffer.slice(0, idx);
            }
        }
    }

    Component.onCompleted: root._restartResolve()
}
