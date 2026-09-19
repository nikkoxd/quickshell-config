import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import qs.Core
import qs.Services

// The island's idle view: a single row of ambient indicators around a centre
// that is the clock, the current lyric line or a running countdown. All three
// centres are built up front and cross-faded, so the surrounding chrome is
// written once and every indicator added here shows up under each of them.
View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding * 2
    implicitHeight: Config.island.height

    // The dashboard's middle panel and the island's centre are one choice, made
    // in DashboardService. Lyrics only make sense while something is actually
    // playing, so a paused or absent player falls back to the clock, and the
    // config switch keeps the clock even when one is.
    readonly property bool showLyrics: Config.island.displayLyrics && !root.showTimer && DashboardService.panel === 1 && MprisService.isPlaying === true

    // A running countdown takes the centre over both of them: it is short
    // lived, the user asked for it explicitly, and the clock it replaces is
    // still a glance away.
    readonly property bool showTimer: TimerService.active

    readonly property bool barsVisualizer: Config.visualizer.mode === "bars"

    Row {
        id: row
        spacing: 8
        anchors.centerIn: parent

        SongArtwork {
            anchors.verticalCenter: parent.verticalCenter
        }

        CavaBars {
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: centre
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.showTimer ? timer.implicitWidth : root.showLyrics ? lyrics.implicitWidth : clock.implicitWidth
            implicitHeight: Math.max(clock.implicitHeight, Math.max(timer.implicitHeight, lyrics.implicitHeight))

            ThemedText {
                id: clock
                anchors.centerIn: parent
                text: DateService.hours + ":" + DateService.minutes
                opacity: root.showLyrics || root.showTimer ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }

            ThemedText {
                id: timer
                anchors.centerIn: parent
                text: TimerService.display
                opacity: root.showTimer ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }

            LyricsText {
                id: lyrics
                anchors.centerIn: parent
                opacity: root.showLyrics && !root.showTimer ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        RecordingIndicator {
            anchors.verticalCenter: parent.verticalCenter
        }

        NotificationIndicator {
            anchors.verticalCenter: parent.verticalCenter
        }

        TimerIndicator {
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: "microphone-slash"
            font.pixelSize: 13
            icon: true
            visible: Pipewire.defaultAudioSource?.audio.muted
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: "speaker-slash"
            font.pixelSize: 13
            icon: true
            visible: Pipewire.defaultAudioSink?.audio.muted
            anchors.verticalCenter: parent.verticalCenter
        }

        ScreenshotIndicator {
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
