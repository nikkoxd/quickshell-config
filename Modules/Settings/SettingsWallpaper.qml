import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

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

    SettingsOption {
        title: "Transition"
        value: Config.wallpaper.transition
        options: WallpaperService.transitions
        onEdited: value => Config.wallpaper.transition = value
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Random transition"
        value: Config.wallpaper.randomTransition
        onChecked: value => Config.wallpaper.randomTransition = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Mute scenes"
        value: Config.wallpaper.sceneMuted
        onChecked: value => Config.wallpaper.sceneMuted = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Scene volume"
        value: Config.wallpaper.sceneVolume
        enabled: !Config.wallpaper.sceneMuted
        onEdited: value => {
            const volume = parseInt(value, 10);
            if (!isNaN(volume) && volume >= 0 && volume <= 100)
                Config.wallpaper.sceneVolume = volume;
        }
        type: SettingsOption.Type.TextField
    }
}
