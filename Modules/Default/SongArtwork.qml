import Quickshell.Widgets
import QtQuick
import qs.Core
import qs.Services

ClippingRectangle {
    id: root
    width: 24
    height: 24
    radius: 4
    color: "transparent"
    visible: Config.visualizer.displayArtwork
             && MprisService.isPlaying

    Rectangle {
        anchors.fill: parent
        color: Config.colorscheme.fg
        opacity: 0.1
    }

    ThemedText {
        text: "music-note-simple"
        icon: true
        anchors.centerIn: parent
    }

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: MprisService.activePlayer.trackArtUrl
    }
}
