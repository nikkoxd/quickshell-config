pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Core

Singleton {
    id: root

    // "idle" | "loading" | "synced" | "plain" | "instrumental" | "none" | "error"
    property string state: "idle"
    property var lines: []
    property string plain: ""
    property string error: ""
    // Whether the lines carry per-word timings, so a fill can step word by word
    // instead of sweeping the whole line at once. Rare: LRCLIB only has them for
    // a handful of tracks, and only in its `lyricsfile` rendering.
    property bool worded: false

    readonly property bool synced: root.state === "synced"

    readonly property string trackKey: {
        const player = MprisService.activePlayer;
        if (!player)
            return "";
        // Escaped, not a literal NUL - an embedded NUL byte makes git treat this file as binary.
        return [player.trackTitle || "", player.trackArtist || "", player.trackAlbum || ""].join("\u0000");
    }

    // How far the lyrics timeline sits from playback, in seconds. Fetched stamps
    // are routinely a fraction of a second off the recording they were made for,
    // so everything that reads a playback position puts it on this timeline first
    // and everything that writes one back (seek) takes the shift off again.
    readonly property real offset: Config.island.lyricsOffset / 1000

    /// Where on the lyrics timeline a playback position of `position` falls.
    function timelineAt(position) {
        return position - root.offset;
    }

    property int currentIndex: root.indexAt(root.lines, root.timelineAt(MprisService.position))
    readonly property string currentText: currentIndex >= 0 && currentIndex < lines.length ? lines[currentIndex].text : ""

    readonly property real currentLineStart: currentIndex >= 0 && currentIndex < lines.length ? lines[currentIndex].time : 0
    // Lines carry their own end where the source gave one, which is what lets a fill
    // finish on the last word and hold instead of creeping through a pause. The last
    // line has no successor to fall back on, so it gets a nominal window.
    readonly property real currentLineEnd: {
        if (root.currentIndex < 0 || root.currentIndex >= root.lines.length)
            return 0;
        const line = root.lines[root.currentIndex];
        if (line.end !== undefined && line.end !== null)
            return line.end;
        if (root.currentIndex + 1 < root.lines.length)
            return root.lines[root.currentIndex + 1].time;
        return root.currentLineStart + 4;
    }

    /// How far playback has advanced through the current line at `position`, 0..1.
    /// `position` is already on the lyrics timeline - sweepAt is what shifts the
    /// playback position callers hand it.
    function progressAt(position) {
        if (currentIndex < 0 || currentIndex >= lines.length)
            return 0;
        const span = root.currentLineEnd - root.currentLineStart;
        if (span <= 0)
            return 1;
        return Math.max(0, Math.min(1, (position - root.currentLineStart) / span));
    }

    /// Last word whose stamp has already passed, or -1 before the first one.
    function wordAt(words, position) {
        if (!words || words.length === 0)
            return -1;

        let lo = 0;
        let hi = words.length;
        while (lo < hi) {
            const mid = (lo + hi) >> 1;
            if (words[mid].time <= position)
                lo = mid + 1;
            else
                hi = mid;
        }
        return lo - 1;
    }

    // Each word starts fast and settles into its end, which is what makes a
    // word-by-word fill read as syllables rather than as one even sweep.
    function easeOutCubic(t) {
        const rest = 1 - t;
        return 1 - rest * rest * rest;
    }

    /// The karaoke sweep over the current line at `position`: the span of characters
    /// being filled right now, as `{ from, to, progress }`, where everything before
    /// `from` is already sung. With word timings the span is the word being sung and
    /// it lands exactly on each word boundary; without them it is the whole line,
    /// swept linearly as before. Callers turn the span into pixels themselves -
    /// only they know the font the line was drawn in. Callers run the fill on the
    /// frame clock, so they pass their own extrapolated playback position rather
    /// than the last published one; the lyrics offset is applied here.
    function sweepAt(playbackPosition) {
        const position = root.timelineAt(playbackPosition);
        const line = root.currentIndex >= 0 && root.currentIndex < root.lines.length ? root.lines[root.currentIndex] : null;
        if (!line)
            return {
                from: 0,
                to: 0,
                progress: 0
            };

        const text = line.text || "";
        const words = line.words;
        if (!words || words.length === 0)
            return {
                from: 0,
                to: text.length,
                progress: root.progressAt(position)
            };

        const index = root.wordAt(words, position);
        // Before the first word the line is sung by nobody yet.
        if (index < 0)
            return {
                from: 0,
                to: 0,
                progress: 0
            };

        const word = words[index];
        // Word ends are already capped at the next word's start, so a span never
        // runs past the boundary the next one picks up from.
        const end = word.end === undefined || word.end === null ? root.currentLineEnd : word.end;
        const span = end - word.time;
        const advance = span <= 0 ? 1 : Math.max(0, Math.min(1, (position - word.time) / span));

        return {
            from: word.from,
            to: word.to,
            progress: root.easeOutCubic(advance)
        };
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
        // Back off the lyrics timeline onto playback, so the line clicked is the
        // line that starts playing.
        player.position = root.lines[index].time + root.offset;
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
            root.worded = false;
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
        root.worded = false;
        root.plain = "";
        root.error = "";
        root.state = "loading";

        fetchProcess.running = false;
        fetchProcess.command = command;
        fetchProcess.running = true;
    }

    function apply(payload) {
        root.lines = payload.synced && payload.lines ? payload.lines : [];
        root.worded = !!payload.words && root.lines.length > 0;
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
                    root.worded = false;
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
