import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import qs.Core
import qs.Services

// The island's idle view: a single row of ambient indicators around a centre
// that is either the clock or the current lyric line. Both centres are built
// up front and cross-faded, so the surrounding chrome is written once and
// every indicator added here shows up under both.
View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding * 2
    implicitHeight: Config.island.height

    // The dashboard's middle panel and the island's centre are one choice, made
    // in DashboardService. Lyrics only make sense while something is actually
    // playing, so a paused or absent player falls back to the clock.
    readonly property bool showLyrics: DashboardService.panel === 1 && MprisService.isPlaying === true

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

        TimerIndicator {
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: centre
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.showLyrics ? lyrics.implicitWidth : clock.implicitWidth
            implicitHeight: Math.max(clock.implicitHeight, lyrics.implicitHeight)

            ThemedText {
                id: clock
                anchors.centerIn: parent
                text: DateService.hours + ":" + DateService.minutes
                opacity: root.showLyrics ? 0 : 1
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
                opacity: root.showLyrics ? 1 : 0
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
    }
}
