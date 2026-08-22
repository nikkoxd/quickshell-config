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

    // Player picked in the UI. Falls back to the first available one when it is
    // unset or the selected player goes away.
    property var selectedPlayer: null
    readonly property var activePlayer: {
        const list = root.players.values;
        if (list.length === 0)
            return null;
        if (root.selectedPlayer && list.indexOf(root.selectedPlayer) !== -1)
            return root.selectedPlayer;
        return list[0];
    }

    function selectPlayer(player) {
        root.selectedPlayer = player;
    }
    property var isPlaying: activePlayer && activePlayer.isPlaying
    property real position: activePlayer ? activePlayer.position : 0
    property real length: activePlayer ? activePlayer.length : 0

    Connections {
        target: root.activePlayer
        function onTrackChanged() {
            root.trackChanged();
        }
    }

    // position isn't self-updating - poke the notify signal so bindings re-read it.
    Timer {
        interval: 200
        repeat: true
        running: root.isPlaying && root.activePlayer && root.activePlayer.positionSupported
        onTriggered: root.activePlayer.positionChanged()
    }
}
