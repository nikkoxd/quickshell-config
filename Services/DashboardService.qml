pragma Singleton

import Quickshell

Singleton {
    id: root

    // Which panel the dashboard's middle column shows: 0 = calendar, 1 = lyrics.
    // Lives here so it survives the view being destroyed when the dashboard closes.
    property int panel: 0

    function togglePanel() {
        root.panel = root.panel === 0 ? 1 : 0;
    }
}
