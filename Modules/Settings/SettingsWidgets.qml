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
            value: SettingsDraft.get("widgets", "lyricsEnabled")
            onChecked: value => SettingsDraft.set("widgets", "lyricsEnabled", value)
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Only while playing"
            value: SettingsDraft.get("widgets", "lyricsOnlyWhilePlaying")
            onChecked: value => SettingsDraft.set("widgets", "lyricsOnlyWhilePlaying", value)
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Center lines"
            value: SettingsDraft.get("widgets", "lyricsCentered")
            onChecked: value => SettingsDraft.set("widgets", "lyricsCentered", value)
            type: SettingsOption.Type.Switch
        }

        SettingsOption {
            title: "Visible rows"
            value: SettingsDraft.get("widgets", "lyricsRows")
            onEdited: value => SettingsDraft.set("widgets", "lyricsRows", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Width"
            units: "px"
            value: SettingsDraft.get("widgets", "lyricsWidth")
            onEdited: value => SettingsDraft.set("widgets", "lyricsWidth", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Distance from bottom"
            units: "px"
            value: SettingsDraft.get("widgets", "lyricsBottomMargin")
            onEdited: value => SettingsDraft.set("widgets", "lyricsBottomMargin", parseInt(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Font size"
            step: 0.1
            units: "x"
            value: SettingsDraft.get("widgets", "lyricsFontScale")
            onEdited: value => SettingsDraft.set("widgets", "lyricsFontScale", parseFloat(value))
            type: SettingsOption.Type.TextField
        }

        SettingsOption {
            title: "Current line size"
            step: 0.05
            units: "x"
            value: SettingsDraft.get("widgets", "lyricsActiveScale")
            onEdited: value => SettingsDraft.set("widgets", "lyricsActiveScale", parseFloat(value))
            type: SettingsOption.Type.TextField
        }
    }
}
