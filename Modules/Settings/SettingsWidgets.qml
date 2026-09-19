import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 30
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    ColumnLayout {
        spacing: 10

        SettingsSection {
            text: "Lyrics"
        }

        SettingsOption {
            title: "Display lyrics on desktop"
            value: Config.widgets.lyricsEnabled
            onChecked: value => Config.widgets.lyricsEnabled = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Only while playing"
            value: Config.widgets.lyricsOnlyWhilePlaying
            onChecked: value => Config.widgets.lyricsOnlyWhilePlaying = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Center lines"
            value: Config.widgets.lyricsCentered
            onChecked: value => Config.widgets.lyricsCentered = value
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Visible rows"
            value: Config.widgets.lyricsRows
            onEdited: value => Config.widgets.lyricsRows = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Width"
            units: "px"
            value: Config.widgets.lyricsWidth
            onEdited: value => Config.widgets.lyricsWidth = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Distance from bottom"
            units: "px"
            value: Config.widgets.lyricsBottomMargin
            onEdited: value => Config.widgets.lyricsBottomMargin = parseInt(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Font size"
            units: "x"
            value: Config.widgets.lyricsFontScale
            onEdited: value => Config.widgets.lyricsFontScale = parseFloat(value)
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Current line size"
            units: "x"
            value: Config.widgets.lyricsActiveScale
            onEdited: value => Config.widgets.lyricsActiveScale = parseFloat(value)
            type: SettingsOption.Type.TextField
        }
    }
}
