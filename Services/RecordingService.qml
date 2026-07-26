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

    function toggleRecording() {
        root.recording = !root.recording;
        console.log("[Recorder] Recording status:", root.recording);
        if (root.recording) {
            recordingStartProc.command = [
                "gpu-screen-recorder", "-w", "screen",
                "-f", String(Config.recorder.recordingFramerate),
                "-a", "default_output",
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
                "-a", "default_output",
                "-r", String(Config.recorder.replayDuration),
                "-c", "mp4",
                "-o", expandPath(Config.recorder.replaysFolder),
                "-replay-storage", "disk"
            ]
            replayProc.running = true;
        } else {
            replayProc.running = false;
        }
    }

    function saveReplay() {
        replaySaveProc.running = true;
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
        id: replaySaveProc
        command: ["pkill", "-SIGUSR1", "-f", "gpu-screen-recorder"]
    }
}
