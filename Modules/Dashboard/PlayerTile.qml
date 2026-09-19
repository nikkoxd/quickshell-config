pragma ComponentBehavior: Bound

import Quickshell.Widgets
import QtQuick
import qs.Core
import qs.Services

// The media player as a quick-settings tile: artwork, track, transport, and a
// progress line along the bottom edge. Sized to sit flush with the tile grid,
// and hidden outright when nothing is playing — a layout skips invisible
// children, so the column closes up on its own.
ClippingRectangle {
    id: root

    readonly property var player: MprisService.activePlayer
    readonly property real progress: MprisService.length > 0 ? Math.max(0, Math.min(1, MprisService.position / MprisService.length)) : 0

    // How much of the tile the text may take: everything the artwork, the
    // transport row and the margins do not.
    readonly property real textWidth: root.width - 14 - art.width - 12 - 10 - transport.width - 12

    radius: Config.island.radius * 0.75
    color: Config.colorscheme.surface
    clip: true

    ClippingRectangle {
        id: art
        width: 52
        height: 52
        radius: Config.island.radius / 2
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.alpha(Config.colorscheme.fg, 0.1)

        ThemedText {
            anchors.centerIn: parent
            text: "music-note-simple"
            icon: true
            font.pixelSize: 22
        }

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.player ? root.player.trackArtUrl : ""
            antialiasing: true
            asynchronous: true
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Row {
            id: titleRow
            spacing: 8

            CavaBars {
                id: bars
                anchors.verticalCenter: parent.verticalCenter
            }

            ScrollingText {
                text: root.player ? root.player.trackTitle : ""
                bold: true
                // The bars share this line, so the title only gets what they
                // leave - without this it runs under the transport buttons
                // whenever the inline visualizer is on. A hidden Row keeps its
                // width but takes no space, hence the visibility check.
                maxWidth: root.textWidth - (bars.visible ? bars.width + titleRow.spacing : 0)
            }
        }

        ScrollingText {
            text: root.player ? root.player.trackArtist : ""
            opacity: 0.8
            maxWidth: root.textWidth
        }
    }

    Row {
        id: transport
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        PlayerButton {
            text: "skip-back"
            onClicked: MprisService.previous()
        }

        PlayerButton {
            text: MprisService.isPlaying ? "pause" : "play"
            onClicked: MprisService.togglePlaying()
        }

        PlayerButton {
            text: "skip-forward"
            onClicked: MprisService.next()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: 2
        width: parent.width * root.progress
        color: Config.colorscheme.accent
        visible: root.progress > 0
    }
}
