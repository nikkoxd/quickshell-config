pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    property alias adapter: adapter

    FileView {
        id: root
        path: Qt.resolvedUrl("../settings.json")
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property JsonObject bar: JsonObject {
                property int height: 35
                property int margins: 10
                property int padding: 40
                property int radius: 20
            }
            property JsonObject font: JsonObject {
                property string family: "Google Sans"
                property int size: 14
                property string weight: "Regular"
                property int headingSize: 18
                property string headingWeight: "Regular"
            }
        }
    }
}
