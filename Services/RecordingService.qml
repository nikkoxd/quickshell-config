pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root
    property bool recording: false
    property bool replayRunning: false
    property string recordingPath: ""
    property string screenshotPath: ""
    property bool screenshotTemp: false
    property var visibleWorkspaces: []
    property int pendingKind: RecordingService.Kind.Region

    Timer {
        id: screenshotDelay
        interval: 250
        onTriggered: root.startScreenshot(root.pendingKind)
    }

    function expandPath(path) {
        const home = Quickshell.env("HOME");
        return path
            .replace(/^~(?=\/|$)/, home)
            .replace(/\$HOME/g, home)
            .replace(/\$\{HOME\}/g, home);
    }

    function outputFileName() {
        const folder = expandPath(Config.recorder.recordingsFolder).replace(/\/+$/, "");
        const final = folder + "/recording_" + timestamp() + ".mp4";
        console.log("[Recording] Recording to:", final);
        root.recordingPath = final;
        return final;
    }

    function timestamp() {
        const now = new Date();
        const pad = n => String(n).padStart(2, "0");
        return now.getFullYear()
            + "-" + pad(now.getMonth() + 1)
            + "-" + pad(now.getDate())
            + "_" + pad(now.getHours())
            + "-" + pad(now.getMinutes())
            + "-" + pad(now.getSeconds());
    }

    function screenshotFileName() {
        const stamp = timestamp();
        // Clipboard-only still needs a file on disk: grim writes a file and
        // wl-copy reads one. It is deleted again once wl-copy has the data.
        root.screenshotTemp = !Config.recorder.screenshotSave;
        const final = root.screenshotTemp
            ? "/tmp/island-screenshot-" + stamp + ".png"
            : expandPath(Config.recorder.screenshotsFolder).replace(/\/+$/, "") + "/screenshot_" + stamp + ".png";
        console.log("[Recorder] Screenshot to:", final);
        root.screenshotPath = final;
        return final;
    }

    // The caller closes the island right after asking for this, so the capture
    // waits for the panel to be off screen. The wait has to live here: the view
    // that starts it is destroyed by the StackView before a timer of its own
    // could ever fire.
    function screenshot(kind) {
        if (!Config.recorder.screenshotSave && !Config.recorder.screenshotCopy) {
            NotificationService.notify("Screenshot skipped", "Enable saving or copying in Settings → Recordings");
            return;
        }
        root.pendingKind = kind;
        screenshotDelay.restart();
    }

    function startScreenshot(kind) {
        screenshotFileName();
        if (kind === RecordingService.Kind.Fullscreen) {
            runGrim("");
        } else if (kind === RecordingService.Kind.Region) {
            runSlurp(["slurp"], "");
        } else {
            // Visible workspaces, then window geometries, then a slurp
            // restricted to them (see monitorsProc/clientsProc).
            monitorsProc.running = true;
        }
    }

    function runSlurp(args, regions) {
        // Kill a slurp still hanging around from an earlier capture first: it
        // would otherwise keep this Process busy and the new run would never
        // start (which took both region *and* window mode down, since they
        // share the process).
        slurpProc.running = false;
        slurpProc.regions = regions;
        // Set every run, not once declaratively: writing to stdin in onStarted
        // breaks the initial binding, so from the second run on slurp would
        // launch with no stdin, never receive its regions and hang forever.
        slurpProc.stdinEnabled = true;
        slurpProc.command = args;
        slurpProc.running = true;
    }

    // mkdir runs in the same shell as grim so the folder cannot be missing by
    // the time grim opens the file. The path is a positional argument, never
    // interpolated into the script, so spaces in it are safe.
    function runGrim(geometry) {
        const args = geometry ? ["-g", geometry] : [];
        grimProc.command = [
            "sh", "-c",
            'out="$1"; shift; mkdir -p "$(dirname "$out")" && grim "$@" "$out"',
            "_", root.screenshotPath, ...args
        ];
        grimProc.running = true;
    }

    function notifyScreenshot() {
        if (root.screenshotTemp) {
            NotificationService.notify("Screenshot copied", "Copied to clipboard");
        } else if (Config.recorder.screenshotCopy) {
            NotificationService.notify("Screenshot saved", "Copied to clipboard, saved to: " + root.screenshotPath);
        } else {
            NotificationService.notify("Screenshot saved", "Saved to: " + root.screenshotPath);
        }
    }

    // Sources joined with "|" so they land in a single audio track; passing
    // them as separate -a flags would make separate tracks instead, which not
    // every player plays back.
    function audioArgs() {
        const sources = [];
        if (Config.recorder.recordingAudio) {
            sources.push("default_output");
        }
        if (Config.recorder.recordingMicrophone) {
            sources.push("default_input");
        }
        return sources.length > 0 ? ["-a", sources.join("|")] : [];
    }

    function toggleRecording() {
        setRecording(!root.recording);
    }

    function setRecording(value) {
        if (value === root.recording) {
            return;
        }
        root.recording = value;
        console.log("[Recorder] Recording status:", root.recording);
        if (root.recording) {
            recordingStartProc.command = [
                "gpu-screen-recorder", "-w", "screen",
                "-f", String(Config.recorder.recordingFramerate),
                ...audioArgs(),
                "-o", outputFileName()
            ]
            recordingStartProc.running = true;
        } else if (recordingStartProc.processId) {
            // Signal by pid, not `pkill -f gpu-screen-recorder`: a replay buffer
            // is a second gpu-screen-recorder process and would be killed too.
            recordingStopProc.command = ["kill", "-SIGINT", String(recordingStartProc.processId)];
            recordingStopProc.running = true;
        }
    }

    function toggleReplay() {
        setReplay(!root.replayRunning);
    }

    function setReplay(value) {
        if (value === root.replayRunning) {
            return;
        }
        root.replayRunning = value;
        if (root.replayRunning) {
            replayProc.command = [
                "gpu-screen-recorder", "-w", "screen",
                "-df", "yes", // save in folders based on date
                "-f", String(Config.recorder.recordingFramerate),
                ...audioArgs(),
                "-r", String(Config.recorder.replayDuration),
                "-c", "mp4",
                "-o", expandPath(Config.recorder.replaysFolder),
                "-replay-storage", "disk"
            ]
            // Sweep leftovers first, then start (see cleanupProc.onExited).
            cleanupStaleReplays();
        } else {
            replayProc.running = false;
        }
    }

    function saveReplay() {
        if (!root.replayRunning || !replayProc.processId) {
            NotificationService.notify("Replay not saved", "The replay buffer is not running");
            return;
        }
        replaySaveProc.command = ["kill", "-SIGUSR1", String(replayProc.processId)];
        replaySaveProc.running = true;
    }

    // Remove leftover on-disk replay buffers from a previous run that didn't
    // exit cleanly (e.g. a quickshell restart killed gpu-screen-recorder
    // before it could clean up its own gsr-replay-*.gsr temp folders).
    function cleanupStaleReplays() {
        const folder = expandPath(Config.recorder.replaysFolder).replace(/\/+$/, "");
        cleanupProc.command = [
            "find", folder, "-maxdepth", "1",
            "-type", "d", "-name", "gsr-replay-*.gsr",
            "-exec", "rm", "-rf", "{}", "+"
        ];
        cleanupProc.running = true;
    }

    enum Kind {
        Region,
        Window,
        Fullscreen
    }

    // Which workspaces are on a screen right now. A client's own `visible` flag
    // is true even on workspaces nobody is looking at, so it cannot be used.
    Process {
        id: monitorsProc
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                let monitors = [];
                try {
                    monitors = JSON.parse(text);
                } catch (e) {
                    NotificationService.notify("Screenshot failed", "Could not read the monitor list");
                    return;
                }
                const ids = [];
                for (const monitor of monitors) {
                    ids.push(monitor.activeWorkspace?.id);
                    // 0 when no scratchpad is pulled up on this monitor.
                    if (monitor.specialWorkspace?.id) {
                        ids.push(monitor.specialWorkspace.id);
                    }
                }
                root.visibleWorkspaces = ids;
                clientsProc.running = true;
            }
        }
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                let clients = [];
                try {
                    clients = JSON.parse(text);
                } catch (e) {
                    NotificationService.notify("Screenshot failed", "Could not read the window list");
                    return;
                }
                const regions = clients
                    .filter(client => client.mapped && !client.hidden && root.visibleWorkspaces.includes(client.workspace?.id))
                    .map(client => client.at[0] + "," + client.at[1] + " " + client.size[0] + "x" + client.size[1]);
                if (regions.length === 0) {
                    NotificationService.notify("Screenshot failed", "No windows to capture");
                    return;
                }
                root.runSlurp(["slurp", "-r"], regions.join("\n") + "\n");
            }
        }
    }

    Process {
        id: slurpProc
        // Window mode restricts the selection to these; region mode leaves it
        // empty. Both are set by runSlurp(), never bound here.
        property string regions: ""
        onStarted: {
            if (regions) {
                write(regions);
            }
            // Close stdin, otherwise slurp waits forever for more regions.
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            // Driven off stdout rather than onExited because the two have no
            // guaranteed order. A cancelled slurp prints nothing here, which is
            // exactly the "do nothing, say nothing" case.
            onStreamFinished: {
                const geometry = text.trim();
                if (geometry === "") {
                    console.log("[Recorder] Screenshot cancelled");
                    return;
                }
                root.runGrim(geometry);
            }
        }
    }

    Process {
        id: grimProc
        onExited: exitCode => {
            if (exitCode !== 0) {
                NotificationService.notify("Screenshot failed", "grim exited with code " + exitCode);
                return;
            }
            if (Config.recorder.screenshotCopy) {
                copyProc.command = ["sh", "-c", 'wl-copy --type image/png < "$1"', "_", root.screenshotPath];
                copyProc.running = true;
            } else {
                root.notifyScreenshot();
            }
        }
    }

    Process {
        id: copyProc
        onExited: exitCode => {
            if (exitCode !== 0) {
                NotificationService.notify("Screenshot not copied", "wl-copy exited with code " + exitCode);
                return;
            }
            // wl-copy reads the whole file before it daemonizes, so the temp
            // file is dead weight from here on.
            if (root.screenshotTemp) {
                removeProc.command = ["rm", "-f", root.screenshotPath];
                removeProc.running = true;
            }
            root.notifyScreenshot();
        }
    }

    Process {
        id: removeProc
    }

    Process {
        id: recordingStartProc
        onStarted: console.log("[Recorder] gpu-screen-recorder started recording")
        onExited: (exitCode, exitStatus) => {
            console.log("[Recorder] gpu-screen-recorder exited with code:", exitCode);
            if (exitCode === 0) {
                NotificationService.notify("Recording finished", "Saved to: " + root.recordingPath);
            } else {
                NotificationService.notify("Recording failed", "gpu-screen-recorder exited with code " + exitCode);
            }
        }
    }

    Process {
        id: recordingStopProc
    }

    Process {
        id: replayProc
    }

    Process {
        id: cleanupProc
        onExited: (exitCode) => {
            console.log("[Recorder] Cleaned up stale replay buffers, exit code:", exitCode);
            // Start the replay only once the folder is clean, so find can't
            // race with (and delete) the buffer this run is about to create.
            if (root.replayRunning) {
                replayProc.running = true;
            }
        }
    }

    Process {
        id: replaySaveProc
        onExited: (exitCode) => {
            if (exitCode === 0) {
                NotificationService.notify("Replay saved", "Saved to: " + root.expandPath(Config.recorder.replaysFolder));
            } else {
                NotificationService.notify("Replay not saved", "kill exited with code " + exitCode);
            }
        }
    }
}
