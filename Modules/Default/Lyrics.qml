import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding * 2
    implicitHeight: Config.island.height

    // LRC marks instrumental breaks with empty lines.
    readonly property bool onLine: LyricsService.synced && LyricsService.currentIndex >= 0
    readonly property string displayText: {
        if (root.onLine)
            return LyricsService.currentText || "♪";
        // "synced" before the first timestamp and "plain" both have lyrics but no line to show
        // right now, and statusText is empty for them - the island would otherwise go blank.
        return LyricsService.statusText || "♪";
    }
    // Only a timestamped line can be filled in; status text stays plain.
    readonly property bool karaoke: root.onLine

    readonly property bool barsVisualizer: Config.visualizer.mode === "bars"

    onDisplayTextChanged: {
        lyrics.pendingText = root.displayText;
        textChangeAnim.restart();
    }

    Row {
        id: row
        spacing: 8
        anchors.centerIn: parent

        CavaBars {
            anchors.verticalCenter: parent.verticalCenter
        }

        RecordingIndicator {
            shown: !root.barsVisualizer
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: lyrics
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: base.implicitWidth
            implicitHeight: base.implicitHeight

            property string pendingText: ""
            Component.onCompleted: base.text = root.displayText;

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

                // width is driven by hand rather than bound: `Behavior` would decide whether to animate
                // from whatever `textChangeAnim.running` happened to be at that instant, and the line
                // change and the progress change both land on the same position tick in no fixed order.
                readonly property real target: root.karaoke ? base.implicitWidth * LyricsService.currentProgress : 0

                function snap() {
                    widthAnim.stop();
                    fill.width = fill.target;
                }

                onTargetChanged: {
                    widthAnim.stop();

                    // A new line or a seek rewinds the fill, and text that no longer matches the line
                    // being sung is about to be swapped out - snap, so nothing sweeps backwards or
                    // trails into the incoming line. Once the swap has happened the fill sweeps again,
                    // so it keeps moving smoothly while the new text is still fading in.
                    if (target <= width || base.text !== root.displayText) {
                        width = target;
                        return;
                    }

                    widthAnim.from = width;
                    widthAnim.to = target;
                    widthAnim.start();
                }

                // MprisService.position ticks at 5Hz - smooth the steps into a continuous sweep.
                NumberAnimation {
                    id: widthAnim
                    target: fill
                    property: "width"
                    duration: 220
                    easing.type: Easing.Linear
                }

                ThemedText {
                    width: base.width
                    height: base.height
                    text: base.text
                    font: base.font
                }
            }

            SequentialAnimation {
                id: textChangeAnim

                ParallelAnimation {
                    NumberAnimation {
                        target: lyrics
                        property: "opacity"
                        to: 0
                        duration: 150
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: lyrics
                        property: "scale"
                        to: 0.95
                        duration: 150
                        easing.type: Easing.InQuad
                    }
                }

                ScriptAction {
                    script: {
                        base.text = lyrics.pendingText;
                        // The old line's fill width means nothing under the new text, and this runs
                        // while the text is fully faded out, so the jump is invisible. Deferred because
                        // implicitWidth only catches up with the new text after a relayout.
                        Qt.callLater(fill.snap);
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: lyrics
                        property: "opacity"
                        to: 1
                        duration: 250
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: lyrics
                        property: "scale"
                        to: 1
                        duration: 350
                        easing.type: Easing.OutBack  // subtle overshoot/bounce
                    }
                }
            }
        }

        ThemedText {
            text: "microphone-slash"
            font.pixelSize: 13
            icon: true
            visible: Pipewire.defaultAudioSink?.audio.muted
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: "speaker-slash"
            font.pixelSize: 13
            icon: true
            visible: Pipewire.defaultAudioSource?.audio.muted
            anchors.verticalCenter: parent.verticalCenter
        }

        RecordingIndicator {
            shown: root.barsVisualizer
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
