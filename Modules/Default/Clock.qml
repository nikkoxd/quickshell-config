import Quickshell.Services.Pipewire
import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding * 2
    implicitHeight: Config.island.height

    readonly property bool barsVisualizer: Config.visualizer.mode === "bars"

    Row {
        id: row
        spacing: 8
        anchors.centerIn: parent

        CavaBars {
            anchors.verticalCenter: parent.verticalCenter
        }

        RecordingIndicator {
            shown: !root.barsVisualizer
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            id: text
            text: DateService.hours + ":" + DateService.minutes
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: "microphone-slash"
            font.pixelSize: 13
            icon: true
            visible: Pipewire.defaultAudioSource?.audio.muted
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: "speaker-slash"
            font.pixelSize: 13
            icon: true
            visible: Pipewire.defaultAudioSink?.audio.muted
            anchors.verticalCenter: parent.verticalCenter
        }

        RecordingIndicator {
            shown: root.barsVisualizer
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
