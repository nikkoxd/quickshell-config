pragma Singleton

import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root
    property bool recording: false
    property bool replayRunning: false

    function expandPath(path) {
        const home = Quickshell.env("HOME");
        return path
            .replace(/^~(?=\/|$)/, home)
            .replace(/\$HOME/g, home)
            .replace(/\$\{HOME\}/g, home);
    }

    function outputFileName() {
        const now = new Date();
        const pad = n => String(n).padStart(2, "0");
        const stamp = now.getFullYear()
            + "-" + pad(now.getMonth() + 1)
            + "-" + pad(now.getDate())
            + "_" + pad(now.getHours())
            + "-" + pad(now.getMinutes())
            + "-" + pad(now.getSeconds());
        const folder = expandPath(Config.recorder.recordingsFolder).replace(/\/+$/, "");
        const final = folder + "/recording_" + stamp + ".mp4";
        console.log("[Recording] Recording to:", final);
        return final;
    }

    function screenshot() {
    }

    function audioArgs() {
        return Config.recorder.recordingAudio ? ["-a", "default_output"] : [];
    }

    function toggleRecording() {
        root.recording = !root.recording;
        console.log("[Recorder] Recording status:", root.recording);
        if (root.recording) {
            recordingStartProc.command = [
                "gpu-screen-recorder", "-w", "screen",
                "-f", String(Config.recorder.recordingFramerate),
                ...audioArgs(),
                "-o", outputFileName()
            ]
            recordingStartProc.running = true;
        } else {
            recordingStopProc.running = true;
        }
    }

    function toggleReplay() {
        root.replayRunning = !root.replayRunning;
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

    Process {
        id: grimProc
    }

    Process {
        id: recordingStartProc
        onStarted: console.log("[Recorder] gpu-screen-recorder started recording")
        onExited: (exitCode, exitStatus) => console.log("[Recorder] gpu-screen-recorder exited with code:", exitCode);
    }

    Process {
        id: recordingStopProc
        command: ["pkill", "-SIGINT", "-f", "gpu-screen-recorder"]
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
        command: ["pkill", "-SIGUSR1", "-f", "gpu-screen-recorder"]
    }
}
