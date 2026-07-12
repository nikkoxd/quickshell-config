pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    property alias adapter: adapter

    FileView {
        id: root
        path: Qt.resolvedUrl("../Themes/Moonfly.json")
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property string bg: "#080808"
            property string bg2: "#1c1c1c"
            property string bg3: "#2a2a2a"
            property string bg4: "#3a3a3a"
            property string fg: "#dadada"
            property string accent: "#bfad9e"
        }
    }
}
