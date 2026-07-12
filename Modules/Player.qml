import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: row.implicitWidth + 20
    implicitHeight: row.implicitHeight + 20

    Timer {
        id: timer
        interval: 5000
        running: true
        onTriggered: {
            root.closeRequested();
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                timer.running = false;
            } else {
                timer.running = true;
            }
        }
    }

    TapHandler {
        onTapped: root.closeRequested()
    }

    Row {
        id: row
        spacing: 10
        anchors.centerIn: parent

        ClippingRectangle {
            width: row.implicitHeight
            height: row.implicitHeight
            radius: width / 2
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Config.colorscheme.fg
                opacity: 0.1
            }

            ThemedText {
                text: "music_note"
                icon: true
                isHeading: true
                anchors.centerIn: parent
            }

            Image {
                source: MprisService.activePlayer.trackArtUrl
                anchors.fill: parent
                asynchronous: true
            }
        }

        Column {
            spacing: 2

            ThemedText {
                text: "Now Playing"
                font.pixelSize: 12
                opacity: 0.5
            }

            ScrollingText {
                text: MprisService.activePlayer.trackArtist + " - " + MprisService.activePlayer.trackTitle
                maxWidth: 200
            }
        }
    }
}
