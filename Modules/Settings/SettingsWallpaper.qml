import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    SettingsOption {
        title: "Output"
        value: Config.wallpaper.output
        onEdited: value => Config.wallpaper.output = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Current wallpaper"
        value: Config.wallpaper.current
        onEdited: value => Config.wallpaper.current = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Image folder"
        value: Config.wallpaper.staticWallpaperFolder
        onEdited: value => Config.wallpaper.staticWallpaperFolder = value
        type: SettingsOption.Type.TextField
    }
}
