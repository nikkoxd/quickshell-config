pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    signal trackChanged()
    function next() {
        root.activePlayer.next();
    }
    function previous() {
        root.activePlayer.previous();
    }
    function togglePlaying() {
        root.activePlayer.togglePlaying();
    }
    property var players: Mpris.players
    property var activePlayer: players.values[0]
    property var isPlaying: activePlayer && activePlayer.isPlaying

    Connections {
        target: root.activePlayer
        function onTrackChanged() {
            root.trackChanged();
        }
    }
}
