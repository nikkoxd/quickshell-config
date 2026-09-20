pragma Singleton

import Quickshell
import qs.Core

Singleton {
    id: root

    // Which panel the dashboard's middle column shows: 0 = calendar, 1 = lyrics.
    // Also picks the island's default view (clock or lyrics), so the two always
    // agree and toggling one toggles the other. Lives here so it survives the
    // view being destroyed when the dashboard closes.
    property int panel: 0

    function togglePanel() {
        root.panel = root.panel === 0 ? 1 : 0;
    }

    // Lyrics take the panel over on their own once a track has them and hand it
    // back when one does not. Only the transition is acted on, so a manual
    // toggle sticks until availability changes again. Config.island.displayLyrics
    // off holds back that automatic half only - togglePanel() still reaches
    // lyrics, so the ipc call and the dashboard's own toggle keep working.
    readonly property bool lyricsAvailable: LyricsService.state === "synced" || LyricsService.state === "plain"
    onLyricsAvailableChanged: root.panel = root.lyricsAvailable && Config.island.displayLyrics ? 1 : 0
}
