import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import QtQuick
import qs.Core
import qs.Services

// The island's idle view: a single row of ambient indicators around a centre
// that is the clock, the current lyric line, a running countdown or the
// workspace strip. Every centre is built up front and cross-faded, so the
// surrounding chrome is written once and every indicator added here shows up
// under each of them.
//
// The centre is anchored to the island's middle rather than laid out in the
// row, so the clock stays put no matter how lopsided the chrome is; the width
// reserves the wider of the two flanks on both sides, which is the padding
// that keeps it there.
View {
    id: root
    implicitWidth: centre.implicitWidth + Math.max(root.leftWidth, root.rightWidth) * 2 + Config.island.padding * 2
    implicitHeight: Config.island.height

    // The gap between indicators inside a flank, and the wider one that sets
    // the centre apart from the flanks either side of it.
    readonly property int spacing: 8
    readonly property int centreSpacing: 16

    // A flank only claims its gap to the centre when it actually has something
    // in it, so an empty side collapses instead of padding twice.
    readonly property real leftWidth: leftRow.implicitWidth > 0 ? leftRow.implicitWidth + root.centreSpacing : 0
    readonly property real rightWidth: rightRow.implicitWidth > 0 ? rightRow.implicitWidth + root.centreSpacing : 0

    // The dashboard's middle panel and the island's centre are one choice, made
    // in DashboardService. Lyrics only make sense while something is actually
    // playing, so a paused or absent player falls back to the clock, and the
    // config switch keeps the clock even when one is.
    readonly property bool showLyrics: Config.island.displayLyrics && !root.showTimer && DashboardService.panel === 1 && MprisService.isPlaying === true

    // A running countdown takes the centre over both of them: it is short
    // lived, the user asked for it explicitly, and the clock it replaces is
    // still a glance away.
    readonly property bool showTimer: TimerService.active

    // A workspace change flashes the workspace strip through the centre and
    // then hands it back, so it outranks all three for the second it is up.
    readonly property bool showWorkspaces: workspacesTimer.running

    // The centre is a stack of four, one of which wins. Each flag is spelled out
    // so the fade and the pop scale can both be driven off it: scale cannot be
    // derived from opacity, because an element already at zero opacity would do
    // its shrink after it has stopped being drawn.
    readonly property bool centreWorkspaces: root.showWorkspaces
    readonly property bool centreTimer: root.showTimer && !root.showWorkspaces
    readonly property bool centreLyrics: root.showLyrics && !root.showTimer && !root.showWorkspaces
    readonly property bool centreClock: !root.showLyrics && !root.showTimer && !root.showWorkspaces

    readonly property bool barsVisualizer: Config.visualizer.mode === "bars"

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            workspacesTimer.restart();
        }
    }

    Timer {
        id: workspacesTimer
        interval: 1000
    }

    // Every indicator goes in through a PopIn instead of hiding itself, so the
    // slot it takes in the row opens and closes with it and the island's width
    // Behavior in Bar.qml follows the row rather than jumping to meet it.
    Row {
        id: leftRow
        spacing: root.spacing
        anchors.right: centre.left
        anchors.rightMargin: root.centreSpacing
        anchors.verticalCenter: parent.verticalCenter

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: artwork.active

            SongArtwork {
                id: artwork
            }
        }

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: bars.active

            CavaBars {
                id: bars
                // The wrapper owns the showing now; `active` is only the
                // condition it is driven by.
                visible: true
            }
        }
    }

    Item {
        id: centre
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.showWorkspaces ? workspaces.implicitWidth : root.showTimer ? timer.implicitWidth : root.showLyrics ? lyrics.implicitWidth : clock.implicitWidth
        implicitHeight: Math.max(clock.implicitHeight, Math.max(timer.implicitHeight, Math.max(lyrics.implicitHeight, workspaces.implicitHeight)))

        ThemedText {
            id: clock
            anchors.centerIn: parent
            text: DateService.hours + ":" + DateService.minutes
            opacity: root.centreClock ? 1 : 0
            scale: root.centreClock ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }
        }

        ThemedText {
            id: timer
            anchors.centerIn: parent
            text: TimerService.display
            opacity: root.centreTimer ? 1 : 0
            scale: root.centreTimer ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }
        }

        LyricsText {
            id: lyrics
            anchors.centerIn: parent
            opacity: root.centreLyrics ? 1 : 0
            scale: root.centreLyrics ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }
        }

        Workspaces {
            id: workspaces
            anchors.centerIn: parent
            opacity: root.centreWorkspaces ? 1 : 0
            scale: root.centreWorkspaces ? 1 : 0.8
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }
        }
    }

    Row {
        id: rightRow
        spacing: root.spacing
        anchors.left: centre.right
        anchors.leftMargin: root.centreSpacing
        anchors.verticalCenter: parent.verticalCenter

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: recording.active

            RecordingIndicator {
                id: recording
            }
        }

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: notifications.active

            NotificationIndicator {
                id: notifications
            }
        }

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: timerBadge.active

            TimerIndicator {
                id: timerBadge
            }
        }

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: Pipewire.defaultAudioSource?.audio.muted ?? false

            ThemedText {
                text: "microphone-slash"
                font.pixelSize: 13
                icon: true
            }
        }

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: Pipewire.defaultAudioSink?.audio.muted ?? false

            ThemedText {
                text: "speaker-slash"
                font.pixelSize: 13
                icon: true
            }
        }

        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: screenshot.active

            ScreenshotIndicator {
                id: screenshot
            }
        }
    }
}
