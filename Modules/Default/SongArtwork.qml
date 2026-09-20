import Quickshell.Widgets
import QtQuick
import qs.Core
import qs.Services

ClippingRectangle {
    id: root
    width: 24
    height: 24
    radius: width / 2
    color: "transparent"

    // The owner wraps this in a PopIn and drives it from here, so the artwork
    // grows out of the row instead of blinking into it.
    readonly property bool active: Config.visualizer.displayArtwork
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
