import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import qs.Core

Column {
    id: root
    spacing: 10
    required property PwNode node
    property string appName: node.properties["application.name"]
        ?? (node.description !== "" ? node.description : node.name)
    property string mediaName: node.properties["media.name"]

    PwObjectTracker {
        objects: [root.node]
    }

    Row {
        spacing: 5

        IconImage {
            source: Quickshell.iconPath(root.appName.toLowerCase(), true)
            width: parent.height
            height: parent.height
            asynchronous: true
            visible: source.toString().length > 0
        }

        ThemedText {
            text: root.appName
        }

        ThemedText {
            text: root.mediaName
            opacity: 0.5
        }
    }

    MixerSlider {
        id: slider
        value: root.node.audio.volume
        icon: "speaker-high"
        onValueChanged: root.node.audio.volume = value
    }
}
