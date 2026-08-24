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
    property string mediaName: node.properties["media.name"] ?? ""

    PwObjectTracker {
        objects: [root.node]
    }

    Row {
        id: label
        width: root.width
        spacing: 5
        clip: true

        IconImage {
            source: Quickshell.iconPath(root.appName.toLowerCase(), true)
            width: parent.height
            height: parent.height
            asynchronous: true
            visible: source.toString().length > 0
        }

        ThemedText {
            id: appLabel
            text: root.appName
        }

        // Whatever is left of the row, so a long track title is cut off instead
        // of pushing the island wider.
        ThemedText {
            width: Math.max(0, label.width - appLabel.width - x)
            text: root.mediaName
            elide: Text.ElideRight
            opacity: 0.5
        }
    }

    Slider {
        id: slider
        width: root.width
        value: root.node.audio.volume
        icon: "speaker-high"
        trackColor: Config.colorscheme.bg
        onValueChanged: root.node.audio.volume = value
    }
}
