pragma Singleton

import QtQuick
import Quickshell

// Countdown timer shared by the timer view and the launcher entries.
//
// The remaining time is derived from a wall-clock deadline instead of being
// decremented by the tick, so a late or coalesced tick (the shell is not a
// realtime process) cannot make the countdown drift. Pausing converts the
// deadline back into a plain "milliseconds left" and starting again turns it
// into a fresh deadline.
Singleton {
    id: root

    // Milliseconds left on the current timer, 0 when nothing is set.
    property int remaining: 0
    // Length the current timer was started with, kept for the display.
    property int duration: 0
    // Length of the last timer that was started, kept for repeat().
    property int lastDuration: 0
    property bool running: false

    // A timer exists (running or paused), as opposed to no timer at all.
    readonly property bool active: root.remaining > 0
    readonly property bool paused: root.active && !root.running

    // Rounded up, so a timer started at 10s reads "10" for its first tick
    // instead of flicking to "09" straight away.
    readonly property int totalSeconds: Math.ceil(root.remaining / 1000)
    readonly property int hours: Math.floor(root.totalSeconds / 3600)
    readonly property int minutes: Math.floor(root.totalSeconds / 60) % 60
    readonly property int seconds: root.totalSeconds % 60

    signal finished()

    property double _deadline: 0

    function start(ms) {
        if (ms <= 0)
            return;
        root.duration = ms;
        root.lastDuration = ms;
        root.remaining = ms;
        root._deadline = Date.now() + ms;
        root.running = true;
    }

    function startParts(hours, minutes, seconds) {
        root.start(((hours * 60 + minutes) * 60 + seconds) * 1000);
    }

    function pause() {
        if (!root.running)
            return;
        root.remaining = Math.max(0, Math.round(root._deadline - Date.now()));
        root.running = false;
    }

    function resume() {
        if (root.running || !root.active)
            return;
        root._deadline = Date.now() + root.remaining;
        root.running = true;
    }

    function toggle() {
        if (root.running)
            root.pause();
        else
            root.resume();
    }

    function stop() {
        root.running = false;
        root.remaining = 0;
        root.duration = 0;
    }

    function repeat() {
        if (root.lastDuration > 0)
            root.start(root.lastDuration);
    }

    function _finish() {
        root.running = false;
        root.remaining = 0;
        root.duration = 0;
        NotificationService.notify("Timer", "Time is up");
        root.finished();
    }

    Timer {
        interval: 100
        repeat: true
        running: root.running

        onTriggered: {
            const left = Math.round(root._deadline - Date.now());
            if (left <= 0) {
                root._finish();
                return;
            }
            root.remaining = left;
        }
    }
}
