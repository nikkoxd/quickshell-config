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
    // instead of sweeping the whole line at once. Kugou has them for nearly every
    // track; LRCLIB only for a handful, and only in its `lyricsfile` rendering.
    property bool worded: false

    readonly property bool synced: root.state === "synced"

    // lrclib matches on duration as much as on name, so the length is part of the
    // identity of what to fetch: given the wrong one it answers with a different
    // recording of the same song, whose stamps drift against the one playing. A
    // track that is still loading reports no length yet - or the one it left the
    // previous track with - so the length is in the key and a fetch made before it
    // settled is redone once it lands.
    readonly property int trackLength: Math.round(MprisService.length)

    readonly property string trackKey: {
        const player = MprisService.activePlayer;
        if (!player)
            return "";
        // Escaped, not a literal NUL - an embedded NUL byte makes git treat this file as binary.
        return [player.trackTitle || "", player.trackArtist || "", player.trackAlbum || "", String(root.trackLength)].join("\u0000");
    }

    // Set when the wait for a length has been given up on, for players that never
    // report one at all. Cleared for every new track.
    property bool lengthOptional: false

    // How far the lyrics timeline sits from playback, in seconds. Fetched stamps
    // are routinely a fraction of a second off the recording they were made for,
    // so everything that reads a playback position puts it on this timeline first
    // and everything that writes one back (seek) takes the shift off again.
    readonly property real offset: Config.island.lyricsOffset / 1000

    // Every provider Helpers/lyrics.py knows, in its default order.
    readonly property var knownProviders: ["kugou", "lrclib"]

    /// `Config.island.lyricsProviders` cleaned up into `{ name, enabled }` for
    /// every known provider exactly once: unknown and repeated names are dropped,
    /// and a provider the config does not mention yet goes to the bottom, enabled.
    readonly property var providers: {
        const configured = Config.island.lyricsProviders || [];
        const result = [];
        const seen = new Set();
        for (const entry of configured) {
            const name = entry && entry.name;
            if (!root.knownProviders.includes(name) || seen.has(name))
                continue;
            seen.add(name);
            result.push({
                name: name,
                enabled: entry.enabled !== false
            });
        }
        for (const name of root.knownProviders) {
            if (!seen.has(name))
                result.push({
                    name: name,
                    enabled: true
                });
        }
        return result;
    }

    // What --providers is handed; a change refetches the current track.
    readonly property string providerArg: root.providers.filter(p => p.enabled).map(p => p.name).join(",")

    onProviderArgChanged: debounce.restart()

    /// Swap the provider at `index` with the one `delta` places away.
    function moveProvider(index, delta) {
        const next = root.providers.slice();
        const target = index + delta;
        if (index < 0 || index >= next.length || target < 0 || target >= next.length)
            return;
        const moved = next[index];
        next[index] = next[target];
        next[target] = moved;
        Config.island.lyricsProviders = next;
    }

    function setProviderEnabled(index, enabled) {
        const next = root.providers.map(p => ({
                    name: p.name,
                    enabled: p.enabled
                }));
        if (index < 0 || index >= next.length)
            return;
        next[index].enabled = enabled;
        Config.island.lyricsProviders = next;
    }

    /// Where on the lyrics timeline a playback position of `position` falls.
    function timelineAt(position) {
        return position - root.offset;
    }

    property int currentIndex: root.indexAt(root.lines, root.timelineAt(MprisService.position))
    readonly property string currentText: currentIndex >= 0 && currentIndex < lines.length ? lines[currentIndex].text : ""

    /// The line on screen at playback position `playbackPosition`, or -1 before the first.
    /// `currentIndex` follows the published position, which only ticks five times a
    /// second - a view filling lines on the frame clock picks its line off that same
    /// clock instead, or it swaps each line in up to a tick after it has started, and
    /// the fill holds the outgoing one full in the meantime. Word-synced sources stamp
    /// a line on its first syllable, so that tick is the first word already sung.
    /// `lead` (seconds) brings the swap forward, for a view that needs a moment to
    /// get the new line on screen; the fill still waits for the first word.
    function lineIndexAt(playbackPosition, lead) {
        return root.indexAt(root.lines, root.timelineAt(playbackPosition) + (lead || 0));
    }

    // Lines carry their own end where the source gave one, which is what lets a fill
    // finish on the last word and hold instead of creeping through a pause. The last
    // line has no successor to fall back on, so it gets a nominal window.
    function lineEnd(index) {
        if (index < 0 || index >= root.lines.length)
            return 0;
        const line = root.lines[index];
        if (line.end !== undefined && line.end !== null)
            return line.end;
        if (index + 1 < root.lines.length)
            return root.lines[index + 1].time;
        return line.time + 4;
    }

    /// How far playback has advanced through line `index` at `position`, 0..1.
    /// `position` is already on the lyrics timeline - sweepAt is what shifts the
    /// playback position callers hand it.
    function progressAt(index, position) {
        if (index < 0 || index >= root.lines.length)
            return 0;
        const start = root.lines[index].time;
        const span = root.lineEnd(index) - start;
        if (span <= 0)
            return 1;
        return Math.max(0, Math.min(1, (position - start) / span));
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
    /// than the last published one; the lyrics offset is applied here. `lineIndex` is the
    /// line they are showing, from lineIndexAt on that same position; it defaults to
    /// `currentIndex`.
    function sweepAt(playbackPosition, lineIndex) {
        const position = root.timelineAt(playbackPosition);
        const at = lineIndex === undefined ? root.currentIndex : lineIndex;
        const line = at >= 0 && at < root.lines.length ? root.lines[at] : null;
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
                progress: root.progressAt(at, position)
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
        const end = word.end === undefined || word.end === null ? root.lineEnd(at) : word.end;
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

    /// Drop whatever is held and settle into `nextState`.
    function reset(nextState) {
        root.pendingKey = "";
        root.lines = [];
        root.worded = false;
        root.plain = "";
        root.error = "";
        root.state = nextState;
    }

    function load(force) {
        const player = MprisService.activePlayer;
        const title = player && player.trackTitle ? player.trackTitle : "";
        const artist = player && player.trackArtist ? player.trackArtist : "";

        if (!title || !artist) {
            root.reset("idle");
            return;
        }

        // Hold the fetch until the track reports its length, rather than matching on
        // the length of whatever played before it and laying another recording's
        // timings over this one.
        // Nothing left to ask.
        if (root.providerArg === "") {
            lengthFallback.stop();
            root.reset("none");
            return;
        }

        if (root.trackLength <= 0 && !root.lengthOptional) {
            root.reset("loading");
            lengthFallback.restart();
            return;
        }

        lengthFallback.stop();

        const command = [
            "python3",
            Quickshell.shellPath("Helpers/lyrics.py"),
            "fetch",
            "--title",
            title,
            "--artist",
            artist,
            "--providers",
            root.providerArg
        ];

        if (player.trackAlbum)
            command.push("--album", player.trackAlbum);
        if (root.trackLength > 0)
            command.push("--duration", String(root.trackLength));
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

    onTrackKeyChanged: {
        // A new track waits for its own length, however the last one resolved.
        root.lengthOptional = false;
        debounce.restart();
    }

    // MPRIS metadata fields arrive one at a time, so coalesce them into a single fetch.
    Timer {
        id: debounce
        interval: 250
        onTriggered: root.load(false)
    }

    // A length usually lands with the rest of the metadata, but a stream has none
    // to report and a player stuck buffering may take a while - so the wait gives
    // up and looks the track up on its name alone.
    Timer {
        id: lengthFallback
        interval: 2000
        onTriggered: {
            root.lengthOptional = true;
            root.load(false);
        }
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
