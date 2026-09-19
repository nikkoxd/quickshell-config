pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Core
import qs.Services

// The dashboard, top to bottom: a scrollable strip of days, a row of view
// shortcuts, the media player, and a grid of quick-settings toggles bound to
// service state.
View {
    id: root
    // The column's children all fill the width, so it has no implicit width of
    // its own to measure - the island is sized from contentWidth instead.
    implicitWidth: root.contentWidth + Config.island.padding * 2
    implicitHeight: column.implicitHeight + Config.island.padding * 2
    focused: true
    dismissable: false
    displayInFullscreen: true
    closeOnUnhover: true

    // Width of the tile column, and the height of one tile row. The tiles
    // divide the width between them, so widening the dashboard is this one
    // number rather than a per-tile size.
    readonly property int contentWidth: 440
    readonly property int tileHeight: 66
    readonly property int buttonHeight: 36
    readonly property int gap: 8

    // Opening another view replaces this one, so nothing needs to close first.
    function openView(view) {
        root.viewChangeRequested(view);
    }

    // The mute states below only update while their node is tracked.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    ColumnLayout {
        id: column
        width: root.contentWidth
        x: Config.island.padding
        y: Config.island.padding
        spacing: 10

        DateStrip {
            Layout.fillWidth: true
        }

        // Plain navigation: these only swap the island over to another view,
        // so they get the shared IconButton rather than a tile that would
        // imply a state to toggle.
        RowLayout {
            Layout.fillWidth: true
            spacing: root.gap

            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "bell"
                // Capped so a pile of notifications cannot widen the pill past
                // the button it sits on.
                badge: {
                    const count = NotificationService.notifications.length;
                    if (count === 0)
                        return "";
                    return count > 99 ? "99+" : "" + count;
                }
                onClicked: root.openView("notifications")
            }

            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "rocket-launch"
                onClicked: root.openView("launcher")
            }

            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "image"
                onClicked: root.openView("wallpaperSelector")
            }

            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "bluetooth"
                onClicked: root.openView("bluetooth")
            }

            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "faders"
                onClicked: root.openView("mixer")
            }

            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "globe"
                badge: DnsService.custom ? "ON" : ""
                onClicked: root.openView("dns")
            }

            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "timer"
                badge: TimerService.active ? TimerService.display : ""
                onClicked: root.openView("timer")
            }

            // Settings is a window of its own rather than a view, so it is
            // requested through the service the launcher uses and the island
            // falls back to its default view.
            IconButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.buttonHeight
                icon: "gear-six"
                onClicked: {
                    LauncherService.settingsRequested();
                    root.closeRequested();
                }
            }
        }

        PlayerTile {
            Layout.fillWidth: true
            Layout.preferredHeight: root.tileHeight
            visible: MprisService.players.values.length > 0
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: root.gap
            rowSpacing: root.gap

            Tile {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: root.tileHeight
                wide: true
                icon: "bell"
                activeIcon: "bell-slash"
                label: "Do not disturb"
                sublabel: NotificationService.muted ? "On" : "Off"
                active: NotificationService.muted
                onClicked: NotificationService.muted = !NotificationService.muted
            }

            Tile {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: root.tileHeight
                wide: true
                icon: "speaker-high"
                activeIcon: "speaker-slash"
                label: "Output"
                sublabel: active ? "Muted" : "On"
                active: Pipewire.defaultAudioSink?.audio.muted ?? false
                onClicked: {
                    if (Pipewire.defaultAudioSink)
                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                }
            }

            Tile {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: root.tileHeight
                wide: true
                icon: "microphone"
                activeIcon: "microphone-slash"
                label: "Microphone"
                sublabel: active ? "Muted" : "On"
                active: Pipewire.defaultAudioSource?.audio.muted ?? false
                onClicked: {
                    if (Pipewire.defaultAudioSource)
                        Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
                }
            }

            Tile {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: root.tileHeight
                wide: true
                icon: "video-camera"
                label: "Record"
                sublabel: RecordingService.recording ? RecordingService.recordingElapsedText : RecordingService.replayRunning ? "Replay buffer" : "Off"
                active: RecordingService.recording
                onClicked: RecordingService.toggleRecording()
            }
        }
    }
}
