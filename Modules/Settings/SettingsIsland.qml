import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    SettingsOption {
        title: "Height"
        units: "px"
        value: Config.island.height
        onEdited: value => Config.island.height = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Outer margins"
        units: "px"
        value: Config.island.margins
        onEdited: value => Config.island.margins = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Inner padding"
        units: "px"
        value: Config.island.padding
        onEdited: value => Config.island.padding = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Corner radius"
        units: "px"
        value: Config.island.radius
        onEdited: value => Config.island.radius = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Display lyrics"
        value: Config.island.displayLyrics
        onChecked: value => Config.island.displayLyrics = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Lyrics delay"
        units: "ms"
        value: Config.island.lyricsOffset
        onEdited: value => Config.island.lyricsOffset = parseInt(value) || 0
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Hover open delay"
        units: "ms"
        value: Config.island.hoverOpenDelay
        onEdited: value => Config.island.hoverOpenDelay = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Hover close delay"
        units: "ms"
        value: Config.island.hoverCloseDelay
        onEdited: value => Config.island.hoverCloseDelay = parseInt(value)
        type: SettingsOption.Type.TextField
    }
}
