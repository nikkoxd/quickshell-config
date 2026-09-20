import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import QtQuick
import qs.Core
import qs.Services

// The island's idle view: a single row of ambient indicators around a centre
// that is the clock, the current lyric line, a running countdown, the
// workspace strip or the track being announced.
View {
    id: root
    implicitWidth: centre.implicitWidth + root.leftExtent + root.rightExtent
    implicitHeight: Config.island.height
    centreOffset: (root.rightExtent - root.leftExtent) / 2

    readonly property int spacing: 8
    readonly property int centreSpacing: 16

    // A flank only claims its gap to the centre when it actually has something
    // in it, so an empty side collapses instead of padding twice.
    readonly property real leftWidth: leftRow.implicitWidth > 0 ? leftRow.implicitWidth + root.centreSpacing : 0
    readonly property real rightWidth: rightRow.implicitWidth > 0 ? rightRow.implicitWidth + root.centreSpacing : 0

    // The full padding is there to give a bare clock its bubble. A flank on
    // that side is already holding the centre off the edge, so it only needs
    // half of it to clear the island's rounding.
    readonly property real leftPadding: Config.island.padding / (root.leftWidth > 0 ? 2 : 1)
    readonly property real rightPadding: Config.island.padding / (root.rightWidth > 0 ? 2 : 1)

    // Everything on one side of the centre: the flank, its gap to the centre,
    // and the edge padding outside it. The width is the two of them around the
    // centre, and the slide is half their difference.
    readonly property real leftExtent: root.leftWidth + root.leftPadding
    readonly property real rightExtent: root.rightWidth + root.rightPadding

    readonly property bool showLyrics: Config.island.displayLyrics && !root.showTimer && DashboardService.panel === 1 && MprisService.isPlaying === true
    readonly property bool showTimer: TimerService.active
    property bool showWorkspaces: false

    // The track announcement: "artist - track" in the centre and the artwork
    // in place of the visualizer, both for as long as this is set.
    property bool announceTrack: false
    readonly property bool showTrack: root.announceTrack && track.text.length > 0

    readonly property bool centreWorkspaces: root.showWorkspaces
    readonly property bool centreTrack: root.showTrack && !root.showWorkspaces
    readonly property bool centreTimer: root.showTimer && !root.showWorkspaces && !root.showTrack
    readonly property bool centreLyrics: root.showLyrics && !root.showTimer && !root.showWorkspaces && !root.showTrack
    readonly property bool centreClock: !root.showLyrics && !root.showTimer && !root.showWorkspaces && !root.showTrack

    // The left slot holds one of the two: the artwork while a track is being
    // announced, the inline visualizer the rest of the time.
    readonly property bool slotArtwork: artwork.active && root.showTrack
    readonly property bool slotBars: bars.active && !root.slotArtwork

    readonly property bool barsVisualizer: Config.visualizer.mode === "bars"

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.showWorkspaces = true;
            workspacesTimer.restart();
        }
    }

    Timer {
        id: workspacesTimer
        interval: 1000
        onTriggered: root.showWorkspaces = false
    }

    // A new song and a resumed one are the same event as far as the island is
    // concerned: say what is playing, then go back to being idle.
    Connections {
        target: MprisService
        function onTrackChanged() {
            root.announce();
        }
        function onIsPlayingChanged() {
            if (MprisService.isPlaying)
                root.announce();
        }
    }

    function announce() {
        root.announceTrack = true;
        trackTimer.restart();
    }

    Timer {
        id: trackTimer
        interval: 3000
        onTriggered: root.announceTrack = false
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

        // One slot for the two of them, so the swap reads as the artwork
        // taking the visualizer's place rather than the row opening a second
        // gap next to it.
        PopIn {
            anchors.verticalCenter: parent.verticalCenter
            shown: root.slotArtwork || root.slotBars

            Item {
                implicitWidth: root.slotArtwork ? artwork.width : bars.width
                implicitHeight: Math.max(artwork.height, bars.height)

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                // Neither of the two pops: one is taking the other's place in
                // a slot that is already open, so an overshoot would read as a
                // second arrival on top of the swap.
                CrossFade {
                    anchors.centerIn: parent
                    shown: root.slotArtwork

                    SongArtwork {
                        id: artwork
                    }
                }

                CrossFade {
                    anchors.centerIn: parent
                    shown: root.slotBars

                    CavaBars {
                        id: bars
                    }
                }
            }
        }
    }

    Item {
        id: centre
        anchors.horizontalCenter: parent.horizontalCenter
        // Undo the island's own slide, so the centre lands where the row wants
        // it while the island around it stays screen-centred.
        anchors.horizontalCenterOffset: -root.centreOffset
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.centreWorkspaces ? workspaces.implicitWidth : root.centreTrack ? track.implicitWidth : root.centreTimer ? timer.implicitWidth : root.centreLyrics ? lyrics.implicitWidth : clock.implicitWidth
        implicitHeight: Math.max(clock.implicitHeight, Math.max(timer.implicitHeight, Math.max(track.implicitHeight, Math.max(lyrics.implicitHeight, workspaces.implicitHeight))))

        // Same curve as the island's slide and resize, so the two halves of
        // the trick stay cancelled out for the whole animation instead of only
        // at either end of it.
        Behavior on anchors.horizontalCenterOffset {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        // The centre is one slot with five members, so none of them pops in:
        // whichever arrives is replacing the one leaving, and the overshoot
        // belongs to an indicator turning up in a slot of its own.
        CrossFade {
            anchors.centerIn: parent
            shown: root.centreClock

            ThemedText {
                id: clock
                text: DateService.hours + ":" + DateService.minutes
            }
        }

        CrossFade {
            anchors.centerIn: parent
            shown: root.centreTimer

            ThemedText {
                id: timer
                text: TimerService.display
            }
        }

        CrossFade {
            anchors.centerIn: parent
            shown: root.centreLyrics

            LyricsText {
                id: lyrics
            }
        }

        CrossFade {
            anchors.centerIn: parent
            shown: root.centreTrack

            TrackText {
                id: track
            }
        }

        CrossFade {
            anchors.centerIn: parent
            shown: root.centreWorkspaces

            Workspaces {
                id: workspaces
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
