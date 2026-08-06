import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Services

Column {
    id: root
    spacing: 15
    readonly property var player: MprisService.activePlayer
    readonly property bool playing: player && player.playbackState == MprisPlaybackState.Playing
    readonly property string trackTitle: player && player.trackTitle
    readonly property string trackAlbum: player && player.trackAlbum
    readonly property string trackArtist: player && player.trackArtist
    readonly property string trackArtUrl: player && player.trackArtUrl

    ClippingRectangle {
        id: imageMask
        width: 150
        height: 150
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Config.colorscheme.fg
            opacity: 0.1
        }

        ThemedText {
            text: "music-note-simple"
            icon: true
            font.pixelSize: 48
            anchors.centerIn: parent
        }

        PropertyAnimation {
            target: image
            property: "rotation"
            to: 360
            duration: 60000
            loops: Animation.Infinite
            running: root.playing
        }

        Image {
            id: image
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.trackArtUrl
            antialiasing: true
            asynchronous: true
        }

        Item {
            id: overlay
            anchors.fill: parent
            opacity: 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Config.colorscheme.bg
                opacity: 0.65
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                PlayerButton {
                    text: "skip-back"
                    onClicked: root.player.previous()
                }

                PlayerButton {
                    text: MprisService.activePlayer.isPlaying ? "pause" : "play"
                    onClicked: root.player.togglePlaying()
                }

                PlayerButton {
                    text: "skip-forward"
                    onClicked: root.player.next()
                }
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    overlay.opacity = 1;
                } else {
                    overlay.opacity = 0;
                }
            }
        }
    }

    Column {
        spacing: 5
        anchors.left: parent.left
        anchors.right: parent.right

        ScrollingText {
            text: root.trackTitle
            isHeading: true
            bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            maxWidth: 150
        }

        ScrollingText {
            text: root.trackAlbum
            opacity: 0.8
            anchors.horizontalCenter: parent.horizontalCenter
            centered: true
            maxWidth: 150
        }

        ScrollingText {
            text: root.trackArtist
            opacity: 0.8
            anchors.horizontalCenter: parent.horizontalCenter
            centered: true
            maxWidth: 150
        }
    }
}
