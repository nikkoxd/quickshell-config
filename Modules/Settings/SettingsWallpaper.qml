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

    SettingsSection {
        text: "Parallax"
    }

    SettingsOption {
        title: "Enabled"
        value: Config.wallpaper.parallax
        onChecked: value => Config.wallpaper.parallax = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Driven by"
        value: Config.wallpaper.parallaxSource
        options: ["workspace", "cursor", "both"]
        onEdited: value => Config.wallpaper.parallaxSource = value
        type: SettingsOption.Type.ComboBox
    }

    // The wallpaper is drawn this much wider than the screen and slid across
    // the overscan, so each amount is both the travel and the strength.
    SettingsOption {
        title: "Workspace amount"
        units: "%"
        value: Math.round(Config.wallpaper.parallaxAmount * 100)
        onEdited: value => Config.wallpaper.parallaxAmount = parseFloat(value) / 100
        type: SettingsOption.Type.TextField
    }

    // 0 spreads the pan over whatever workspaces exist at the time.
    SettingsOption {
        title: "Workspaces spanned"
        value: Config.wallpaper.parallaxWorkspaces
        onEdited: value => Config.wallpaper.parallaxWorkspaces = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Workspace duration"
        units: "ms"
        value: Config.wallpaper.parallaxDuration
        onEdited: value => Config.wallpaper.parallaxDuration = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Cursor amount"
        units: "%"
        value: Math.round(Config.wallpaper.parallaxMouseAmount * 100)
        onEdited: value => Config.wallpaper.parallaxMouseAmount = parseFloat(value) / 100
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Cursor duration"
        units: "ms"
        value: Config.wallpaper.parallaxMouseDuration
        onEdited: value => Config.wallpaper.parallaxMouseDuration = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsSection {
        text: "Wallhaven"
    }

    // Downloads land in the image folder above. Only the key lives here: the
    // rest of the search filters are set in the browser itself.
    SettingsOption {
        title: "API key"
        value: Config.wallhaven.apiKey
        onEdited: value => Config.wallhaven.apiKey = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Toplist range"
        value: Config.wallhaven.topRange
        options: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]
        onEdited: value => Config.wallhaven.topRange = value
        type: SettingsOption.Type.ComboBox
    }
}
