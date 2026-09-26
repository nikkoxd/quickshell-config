import QtQuick
import qs.Core
import qs.Services

// The current lyric line, filled in karaoke-style as it is sung. Sized to the
// line it holds, so it drops straight into the default view's row.
Item {
    id: root
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    // LRC marks instrumental breaks with empty lines. This stands in for one.
    readonly property string placeholderText: "♪♪♪"

    readonly property bool onLine: LyricsService.synced && LyricsService.currentIndex >= 0
    readonly property string displayText: {
        if (root.onLine)
            return LyricsService.currentText || root.placeholderText;
        // "synced" before the first timestamp and "plain" both have lyrics but no line to show
        // right now, and statusText is empty for them - the island would otherwise go blank.
        return LyricsService.statusText || root.placeholderText;
    }
    // Only a timestamped line can be filled in; status text stays plain.
    readonly property bool karaoke: root.onLine
    // An empty line has no characters for the sweep to land on, so the placeholder
    // standing in for it is filled as a whole instead, on the line progress the
    // sweep already reports for a line without word timings. Read off the text on
    // screen rather than off the service, so it doesn't lead the line swap.
    readonly property bool placeholder: root.karaoke && base.text === root.placeholderText

    property string pendingText: ""

    // The fill moves with the music rather than with the 5Hz position ticks.
    PlaybackClock {
        id: clock
        // The default view fades this out rather than hiding it, so opacity is
        // what says whether anything is on screen to sweep.
        active: root.visible && root.opacity > 0 && root.karaoke
    }

    // The stretch of the line being filled right now, as character offsets into it
    // plus how far through that stretch playback is. With word timings the stretch
    // is the word being sung, so the fill steps word by word; without them it is the
    // whole line. `from`/`to` only change at a word boundary, so the widths measured
    // off them are measured then and not every frame.
    readonly property var sweep: LyricsService.sweepAt(clock.position)
    readonly property int sweepFrom: root.sweep.from
    readonly property int sweepTo: root.sweep.to
    readonly property real sweepProgress: root.sweep.progress

    FontMetrics {
        id: metrics
        font: base.font
    }

    // The sweep is measured in characters, so it goes through the font to become a
    // fraction of the line's width. Status text is never filled, so it never measures.
    readonly property real spanStart: root.karaoke && !root.placeholder ? metrics.advanceWidth(base.text.substring(0, root.sweepFrom)) : 0
    readonly property real spanEnd: !root.karaoke ? 0 : root.placeholder ? root.metricWidth : metrics.advanceWidth(base.text.substring(0, root.sweepTo))
    readonly property real metricWidth: metrics.advanceWidth(base.text) || 1
    readonly property real fillFraction: Math.max(0, Math.min(1, (root.spanStart + (root.spanEnd - root.spanStart) * root.sweepProgress) / root.metricWidth))

    Component.onCompleted: base.text = root.displayText

    onDisplayTextChanged: {
        root.pendingText = root.displayText;
        textChangeAnim.restart();
    }

    // The line-swap animation drives this rather than the root, so whoever owns
    // this component is still free to fade it in and out as a whole.
    Item {
        id: content
        anchors.centerIn: parent
        implicitWidth: base.implicitWidth
        implicitHeight: base.implicitHeight

        ThemedText {
            id: base
            // The base sits dim while a line is being sung - the fill overlay is what brightens it.
            opacity: root.karaoke ? 0.45 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Karaoke fill: a fully opaque copy of the line, revealed left to right by a clipping mask.
        // Only the mask width changes, so the text is never re-laid out.
        Item {
            id: fill
            height: parent.height
            clip: true
            opacity: root.karaoke ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            // The fill holds while a line that has already been sung is still on screen:
            // the sweep has moved on to the line about to replace it, and running that
            // over the outgoing text would only rewind the fill in front of the viewer.
            // The swap hides the jump when the binding picks up again.
            Binding on width {
                when: base.text === root.displayText
                value: base.implicitWidth * root.fillFraction
                restoreMode: Binding.RestoreNone
            }

            ThemedText {
                width: base.width
                height: base.height
                text: base.text
                font: base.font
            }
        }
    }

    SequentialAnimation {
        id: textChangeAnim

        ParallelAnimation {
            NumberAnimation {
                target: content
                property: "opacity"
                to: 0
                duration: 150
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: content
                property: "scale"
                to: 0.95
                duration: 150
                easing.type: Easing.InQuad
            }
        }

        ScriptAction {
            // The fill picks the new line up here, while the text is fully faded out,
            // so the jump off wherever the old one had reached is invisible.
            script: base.text = root.pendingText
        }

        ParallelAnimation {
            NumberAnimation {
                target: content
                property: "opacity"
                to: 1
                duration: 250
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: content
                property: "scale"
                to: 1
                duration: 350
                easing.type: Easing.OutBack  // subtle overshoot/bounce
            }
        }
    }
}
