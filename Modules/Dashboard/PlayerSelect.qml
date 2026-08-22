import qs.Core
import qs.Services

// Picks which MPRIS player the dashboard follows. Only worth showing when more
// than one is running.
Dropdown {
    id: root

    readonly property var players: MprisService.players.values

    function label(player) {
        if (!player)
            return "No player";
        return player.identity || player.trackTitle || "Unknown player";
    }

    implicitHeight: 28
    horizontalPadding: 8
    radius: Config.island.radius / 2
    backgroundColor: "transparent"
    hoverColor: Config.colorscheme.surface
    enabled: root.players.length > 1

    options: root.players.map(player => ({
                label: root.label(player),
                value: player
            }))
    current: MprisService.activePlayer
    placeholder: "No player"
    onSelected: player => MprisService.selectPlayer(player)
}
