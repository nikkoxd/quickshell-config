import QtQuick
import qs.Services

// The timer indicator shown in the default views, laid out like the
// notification one: a clock glyph plus the time remaining. The glyph pulses
// while the countdown runs; a held timer dims as a whole and carries a pause
// badge over the glyph's bottom-right corner.
Row {
    id: root
    spacing: 3

    // The owner wraps this in a PopIn and drives it from here, which is also
    // what keeps the island from reserving the width when no timer is set.
    readonly property bool active: TimerService.active

    opacity: TimerService.paused ? 0.6 : 1

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

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

    Item {
        // Room for the half of the pause badge that hangs past the glyph, so
        // it doesn't sit on the first digit.
        implicitWidth: glyph.implicitWidth + (TimerService.paused ? 3 : 0)
        implicitHeight: glyph.implicitHeight
        anchors.verticalCenter: parent.verticalCenter

        ThemedText {
            id: glyph
            text: "timer"
            icon: true
            font.pixelSize: 13
            opacity: TimerService.running ? root.blink : 1
        }

        // Same shape as ScreenshotIndicator's check: its own background disc so
        // the glyph underneath can't muddle it, hanging off the corner because
        // a 13px icon has no room inside.
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

    ThemedText {
        text: TimerService.display
        font.pixelSize: 12
        // Tabular figures, so the row keeps its width as the seconds tick
        // instead of nudging the island every second.
        font.features: { "tnum": 1 }
        anchors.verticalCenter: parent.verticalCenter
    }
}
