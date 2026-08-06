pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // "idle" | "loading" | "synced" | "plain" | "instrumental" | "none" | "error"
    property string state: "idle"
    property var lines: []
    property string plain: ""
    property string error: ""

    readonly property bool synced: root.state === "synced"

    readonly property string trackKey: {
        const player = MprisService.activePlayer;
        if (!player)
            return "";
        // Escaped, not a literal NUL - an embedded NUL byte makes git treat this file as binary.
        return [player.trackTitle || "", player.trackArtist || "", player.trackAlbum || ""].join("\u0000");
    }

    property int currentIndex: root.indexAt(root.lines, MprisService.position)
    readonly property string currentText: currentIndex >= 0 && currentIndex < lines.length ? lines[currentIndex].text : ""

    /// How far playback has advanced through the current line, 0..1.
    readonly property real currentProgress: {
        if (currentIndex < 0 || currentIndex >= lines.length)
            return 0;
        const start = lines[currentIndex].time;
        // The last line has no successor to bound it, so give it a nominal window.
        const end = currentIndex + 1 < lines.length ? lines[currentIndex + 1].time : start + 4;
        if (end <= start)
            return 1;
        return Math.max(0, Math.min(1, (MprisService.position - start) / (end - start)));
    }

    /// Placeholder to show in place of lyrics; empty when there are lyrics to show.
    readonly property string statusText: {
        switch (root.state) {
        case "loading":
            return "Loading lyrics…";
        case "instrumental":
            return "Instrumental";
        case "none":
            return "No lyrics found";
        case "error":
            return root.error || "Lyrics unavailable";
        case "idle":
            return "Nothing playing";
        case "plain":
            return root.plain.length > 0 ? "" : "No lyrics found";
        default:
            return "";
        }
    }

    // The key the in-flight fetch was launched for, so a superseded result can be dropped.
    property string pendingKey: ""

    /// Last line whose timestamp has already passed, or -1 before the first one.
    function indexAt(lyricLines, position) {
        if (!lyricLines || lyricLines.length === 0)
            return -1;

        let lo = 0;
        let hi = lyricLines.length;
        while (lo < hi) {
            const mid = (lo + hi) >> 1;
            if (lyricLines[mid].time <= position)
                lo = mid + 1;
            else
                hi = mid;
        }
        return lo - 1;
    }

    function seek(index) {
        const player = MprisService.activePlayer;
        if (!player || !player.canSeek)
            return;
        if (index < 0 || index >= root.lines.length)
            return;
        player.position = root.lines[index].time;
    }

    function refresh() {
        root.load(true);
    }

    function load(force) {
        const player = MprisService.activePlayer;
        const title = player && player.trackTitle ? player.trackTitle : "";
        const artist = player && player.trackArtist ? player.trackArtist : "";

        if (!title || !artist) {
            root.pendingKey = "";
            root.lines = [];
            root.plain = "";
            root.error = "";
            root.state = "idle";
            return;
        }

        const command = [
            "python3",
            Quickshell.shellPath("Helpers/lyrics.py"),
            "fetch",
            "--title",
            title,
            "--artist",
            artist
        ];

        if (player.trackAlbum)
            command.push("--album", player.trackAlbum);
        if (MprisService.length > 0)
            command.push("--duration", String(Math.round(MprisService.length)));
        if (force)
            command.push("--refresh");

        root.pendingKey = root.trackKey;
        root.lines = [];
        root.plain = "";
        root.error = "";
        root.state = "loading";

        fetchProcess.running = false;
        fetchProcess.command = command;
        fetchProcess.running = true;
    }

    function apply(payload) {
        root.lines = payload.synced && payload.lines ? payload.lines : [];
        root.plain = payload.plain || "";
        root.error = payload.error || "";

        if (payload.error)
            root.state = "error";
        else if (!payload.found)
            root.state = "none";
        else if (payload.instrumental)
            root.state = "instrumental";
        else if (root.lines.length > 0)
            root.state = "synced";
        else
            root.state = "plain";
    }

    onTrackKeyChanged: debounce.restart()

    // MPRIS metadata fields arrive one at a time, so coalesce them into a single fetch.
    Timer {
        id: debounce
        interval: 250
        onTriggered: root.load(false)
    }

    Process {
        id: fetchProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.pendingKey !== root.trackKey) {
                    console.log("[lyrics] dropping stale result");
                    return;
                }

                try {
                    root.apply(JSON.parse(this.text));
                } catch (e) {
                    console.log("[lyrics] failed to parse lyrics.py output:", e);
                    root.lines = [];
                    root.plain = "";
                    root.error = "could not read lyrics";
                    root.state = "error";
                }
            }
        }

        stderr: StdioCollector {
            id: fetchStderr
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("[lyrics] lyrics.py exited with", exitCode, fetchStderr.text.trim());
                if (root.pendingKey === root.trackKey && root.state === "loading") {
                    root.error = "lyrics lookup failed";
                    root.state = "error";
                }
            }
        }
    }
}
