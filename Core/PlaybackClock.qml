import QtQuick
import qs.Services

// Playback position on the frame clock, for anything that has to move with the
// music instead of stepping. MprisService publishes a position five times a
// second, so a fill bound straight to it steps rather than sweeps, and smoothing
// those steps with an animation only trades the stepping for a fifth of a second
// of lag. This runs off the last published position and predicts forward instead.
//
// Only ticks while `active`: a FrameAnimation drives the render loop, so one left
// running keeps the shell repainting for nothing.
QtObject {
    id: root

    // Set by whoever is drawing, typically gated on being on screen.
    property bool active: false

    /// Where playback is right now, in seconds.
    property real position: 0

    // Playback position at `anchorWall`, the wall clock the prediction runs from.
    property real anchorPosition: 0
    property real anchorWall: 0

    readonly property real syncedPosition: MprisService.position

    /// Where playback should have reached by wall-clock time `now`, in seconds.
    function predict(now) {
        return root.anchorPosition + (now - root.anchorWall) / 1000;
    }

    // Players re-report positions they have already passed: the same stale reads
    // MprisService settles when they land in one turn, except these arrive a tick
    // apart and up to a tenth of a second behind, several times a second. Snapping
    // the clock onto each of them is what makes a fill stutter, so only a jump big
    // enough to be a seek, a track change or a resume moves it outright - anything
    // smaller is steered out a fraction per tick, and never rewinds by more than a
    // frame's worth.
    readonly property real snapThreshold: 0.5
    readonly property real correctionGain: 0.2
    readonly property real maxRewind: 0.01

    onSyncedPositionChanged: {
        const now = Date.now();
        const predicted = root.predict(now);
        const error = root.syncedPosition - predicted;

        root.anchorPosition = Math.abs(error) > root.snapThreshold ? root.syncedPosition : predicted + Math.max(-root.maxRewind, error * root.correctionGain);
        root.anchorWall = now;
        root.position = root.predict(now);
    }

    readonly property FrameAnimation ticker: FrameAnimation {
        running: root.active && MprisService.isPlaying === true
        onTriggered: root.position = root.predict(Date.now())
    }
}
