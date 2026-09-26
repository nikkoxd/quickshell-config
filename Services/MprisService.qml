pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    signal trackChanged()
    function next() {
        root.activePlayer.next();
    }
    function previous() {
        root.activePlayer.previous();
    }
    function togglePlaying() {
        root.activePlayer.togglePlaying();
    }
    property var players: Mpris.players

    // Player picked in the UI. Falls back to the first available one when it is
    // unset or the selected player goes away.
    property var selectedPlayer: null
    readonly property var activePlayer: {
        const list = root.players.values;
        if (list.length === 0)
            return null;
        if (root.selectedPlayer && list.indexOf(root.selectedPlayer) !== -1)
            return root.selectedPlayer;
        return list[0];
    }

    function selectPlayer(player) {
        root.selectedPlayer = player;
    }
    property var isPlaying: activePlayer && activePlayer.isPlaying
    property real length: activePlayer ? activePlayer.length : 0

    // What the player reports right now, which is not always the truth: players emit a position
    // a second ahead of reality and correct it in the same event loop turn (Sonora does it once
    // a second). Read `position` instead - it is the settled, corrected value.
    readonly property real rawPosition: activePlayer ? activePlayer.position : 0
    property real position: 0

    // `rawPosition` is an extrapolation, not a reading: quickshell fetches Position off the bus
    // when the track or the playback status changes and runs a wall clock forward from there,
    // and nothing in the QML API re-reads it afterwards. A player that is still buffering
    // reports the position it has really reached - none - so that clock counts from a start
    // that has not happened yet, and everything following playback (the lyrics above all) sits
    // that far ahead for the rest of the track. `Helpers/mpris_position.py` reads the real
    // Position back twice a second; what it says is kept here as a correction on top.
    property real reportedPosition: 0
    property real positionOffset: 0
    // Wall clock (seconds) of the last read that actually moved.
    property real lastAdvance: 0
    // The player claims to be playing and its position says otherwise, so it is buffering.
    // Nothing is moving, so neither should anything following it.
    property bool stalled: false

    // Divergence big enough to be the extrapolation having run off rather than the coarseness
    // of the player's own reporting, and so taken off at once instead of being eased out.
    readonly property real offsetSnap: 1.0
    readonly property real offsetGain: 0.25
    // Players report a position at their own granularity - a whole second at a time for some -
    // so only a stretch longer than that without movement says playback has stopped.
    readonly property real stallTimeout: 2.0

    /// Fold a real Position reading, in seconds, into the published position.
    function samplePosition(reported) {
        const now = Date.now() / 1000;
        const moved = Math.abs(reported - root.reportedPosition) > 0.01;

        if (moved) {
            root.lastAdvance = now;
            root.stalled = false;
        } else if (root.isPlaying === true && now - root.lastAdvance > root.stallTimeout) {
            root.stalled = true;
        }

        root.reportedPosition = reported;

        const error = reported - (root.rawPosition + root.positionOffset);
        root.positionOffset += Math.abs(error) > root.offsetSnap ? error : error * root.offsetGain;
        root.publishPosition();
    }

    function publishPosition() {
        // A stalled player has one position and it is the one it reported; predicting past it
        // is exactly what runs the lyrics ahead of a track that has not started sounding.
        root.position = root.stalled ? root.reportedPosition : root.rawPosition + root.positionOffset;
    }

    /// Drop the correction, for when quickshell has just re-read Position itself.
    function resetCorrection() {
        root.positionOffset = 0;
        root.reportedPosition = 0;
        root.lastAdvance = Date.now() / 1000;
        root.stalled = false;
    }

    onRawPositionChanged: settlePosition.restart()
    onIsPlayingChanged: root.resetCorrection()

    // Coalesces a turn's worth of position updates and publishes only the last, so a spike and
    // its correction never reach bindings as two separate values. Without it the current lyric
    // jumps to the next line and straight back, playing the swap animation twice.
    Timer {
        id: settlePosition
        interval: 0
        onTriggered: root.publishPosition()
    }

    // The player being read back, empty when there is nothing worth reading: the probe is a
    // process, and a paused player's position is not going anywhere.
    readonly property string probeBus: root.activePlayer && root.activePlayer.positionSupported && root.isPlaying === true ? root.activePlayer.dbusName : ""

    onProbeBusChanged: {
        positionProbe.running = false;
        if (root.probeBus === "")
            return;
        positionProbe.command = ["python3", Quickshell.shellPath("Helpers/mpris_position.py"), "--bus", root.probeBus, "--interval", "0.5"];
        positionProbe.running = true;
    }

    Process {
        id: positionProbe
        running: false

        stdout: SplitParser {
            onRead: line => {
                const reported = parseFloat(line);
                if (!isNaN(reported))
                    root.samplePosition(reported);
            }
        }

        stderr: SplitParser {
            onRead: line => console.log("[mpris] position probe:", line)
        }
    }

    Connections {
        target: root.activePlayer
        function onTrackChanged() {
            // Quickshell re-reads Position on a track change, so the extrapolation is the truth
            // again for a moment and the correction carried over from the last track is not.
            root.resetCorrection();
            root.trackChanged();
        }
    }

    // position isn't self-updating - poke the notify signal so bindings re-read it.
    Timer {
        interval: 200
        repeat: true
        running: root.isPlaying && root.activePlayer && root.activePlayer.positionSupported
        onTriggered: root.activePlayer.positionChanged()
    }
}
