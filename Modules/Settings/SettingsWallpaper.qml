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
        value: SettingsDraft.get("wallpaper", "output")
        onEdited: value => SettingsDraft.set("wallpaper", "output", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Current wallpaper"
        value: SettingsDraft.get("wallpaper", "current")
        onEdited: value => SettingsDraft.set("wallpaper", "current", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Image folder"
        value: SettingsDraft.get("wallpaper", "staticWallpaperFolder")
        onEdited: value => SettingsDraft.set("wallpaper", "staticWallpaperFolder", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Transition"
        value: SettingsDraft.get("wallpaper", "transition")
        options: WallpaperService.transitions
        onEdited: value => SettingsDraft.set("wallpaper", "transition", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Random transition"
        value: SettingsDraft.get("wallpaper", "randomTransition")
        onChecked: value => SettingsDraft.set("wallpaper", "randomTransition", value)
        type: SettingsOption.Type.Switch
    }

    SettingsSection {
        text: "Parallax"
    }

    SettingsOption {
        title: "Enabled"
        value: SettingsDraft.get("wallpaper", "parallax")
        onChecked: value => SettingsDraft.set("wallpaper", "parallax", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Driven by"
        value: SettingsDraft.get("wallpaper", "parallaxSource")
        options: ["workspace", "cursor", "both"]
        onEdited: value => SettingsDraft.set("wallpaper", "parallaxSource", value)
        type: SettingsOption.Type.ComboBox
    }

    // The wallpaper is drawn this much wider than the screen and slid across
    // the overscan, so each amount is both the travel and the strength.
    SettingsOption {
        title: "Workspace amount"
        maximum: 100
        units: "%"
        value: Math.round(SettingsDraft.get("wallpaper", "parallaxAmount") * 100)
        onEdited: value => SettingsDraft.set("wallpaper", "parallaxAmount", parseFloat(value) / 100)
        type: SettingsOption.Type.TextField
    }

    // 0 spreads the pan over whatever workspaces exist at the time.
    SettingsOption {
        title: "Workspaces spanned"
        value: SettingsDraft.get("wallpaper", "parallaxWorkspaces")
        onEdited: value => SettingsDraft.set("wallpaper", "parallaxWorkspaces", parseInt(value))
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Workspace duration"
        step: 10
        units: "ms"
        value: SettingsDraft.get("wallpaper", "parallaxDuration")
        onEdited: value => SettingsDraft.set("wallpaper", "parallaxDuration", parseInt(value))
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Cursor amount"
        maximum: 100
        units: "%"
        value: Math.round(SettingsDraft.get("wallpaper", "parallaxMouseAmount") * 100)
        onEdited: value => SettingsDraft.set("wallpaper", "parallaxMouseAmount", parseFloat(value) / 100)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Cursor duration"
        step: 10
        units: "ms"
        value: SettingsDraft.get("wallpaper", "parallaxMouseDuration")
        onEdited: value => SettingsDraft.set("wallpaper", "parallaxMouseDuration", parseInt(value))
        type: SettingsOption.Type.TextField
    }

    SettingsSection {
        text: "Wallhaven"
    }

    // Downloads land in the image folder above. The search filters themselves
    // are set in the browser.
    SettingsOption {
        title: "API key"
        value: SettingsDraft.get("wallhaven", "apiKey")
        onEdited: value => SettingsDraft.set("wallhaven", "apiKey", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Toplist range"
        value: SettingsDraft.get("wallhaven", "topRange")
        options: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]
        onEdited: value => SettingsDraft.set("wallhaven", "topRange", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Grid columns"
        // The dropdown matches its current value by ===, and options are
        // strings.
        value: String(SettingsDraft.get("wallhaven", "columns"))
        options: ["3", "4", "5", "6", "7", "8"]
        onEdited: value => SettingsDraft.set("wallhaven", "columns", parseInt(value))
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Hide downloaded"
        value: SettingsDraft.get("wallhaven", "hideDownloaded")
        onChecked: value => SettingsDraft.set("wallhaven", "hideDownloaded", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Preview before download"
        value: SettingsDraft.get("wallhaven", "previewBeforeDownload")
        onChecked: value => SettingsDraft.set("wallhaven", "previewBeforeDownload", value)
        type: SettingsOption.Type.Switch
    }
}
