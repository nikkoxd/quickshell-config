import QtQuick
import qs.Services

// The timer's presence in the default views. The remaining time itself is the
// island's centre, so this is only the state badge: a clock glyph that pulses
// while the countdown runs and carries a pause badge over its bottom-right
// corner while it is held.
Item {
    id: root
    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    // The owner wraps this in a PopIn and drives it from here, which is also
    // what keeps the island from reserving the width when no timer is set.
    readonly property bool active: TimerService.active

    // The blink is driven through a plain property rather than animating the
    // glyph's opacity directly: an animation that stops leaves the property at
    // whatever value it reached, so a paused timer would keep a random dimness.
    property real blink: 1

    SequentialAnimation on blink {
        running: TimerService.running
        loops: Animation.Infinite
        NumberAnimation {
            from: 1
            to: 0.3
            duration: 600
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            from: 0.3
            to: 1
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }

    ThemedText {
        id: glyph
        text: "timer"
        icon: true
        font.pixelSize: 13
        // A paused timer sits steady and dimmed, so the badge reads as the
        // reason it stopped moving.
        opacity: TimerService.running ? root.blink : 0.6
    }

    // Same shape as ScreenshotIndicator's check: its own background disc so the
    // glyph underneath can't muddle it, hanging off the corner because a 13px
    // icon has no room inside.
    Rectangle {
        anchors.horizontalCenter: glyph.right
        anchors.verticalCenter: glyph.bottom
        width: 9
        height: 9
        radius: width / 2
        color: Config.colorscheme.bg
        visible: TimerService.paused

        ThemedText {
            text: "pause"
            icon: true
            font.pixelSize: 7
            color: Config.colorscheme.accent
            anchors.centerIn: parent
        }
    }
}
