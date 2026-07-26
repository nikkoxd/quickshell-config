import QtQuick
import QtQuick.Layouts
import qs.Core

Column {
    id: root
    spacing: 20
    Layout.fillHeight: true

    property int currentTab: Settings.Tab.Island

    ThemedText {
        text: "Settings"
        font.pixelSize: 24
    }

    Column {
        spacing: 10

        SettingsTab {
            text: "Island"
            icon: "mountain_steam"
            selected: root.currentTab === Settings.Tab.Island
            onTapped: root.currentTab = Settings.Tab.Island
        }

        SettingsTab {
            text: "Launcher"
            icon: "rocket_launch"
            selected: root.currentTab === Settings.Tab.Launcher
            onTapped: root.currentTab = Settings.Tab.Launcher
        }

        SettingsTab {
            text: "Recordings"
            icon: "camera"
            selected: root.currentTab === Settings.Tab.Recording
            onTapped: root.currentTab = Settings.Tab.Recording
        }

        SettingsTab {
            text: "Visualizer"
            icon: "graphic_eq"
            selected: root.currentTab === Settings.Tab.Visualizer
            onTapped: root.currentTab = Settings.Tab.Visualizer
        }

        SettingsTab {
            text: "Theme"
            icon: "palette"
            selected: root.currentTab === Settings.Tab.Theme
            onTapped: root.currentTab = Settings.Tab.Theme
        }

        SettingsTab {
            text: "Wallpaper"
            icon: "wallpaper"
            selected: root.currentTab === Settings.Tab.Wallpaper
            onTapped: root.currentTab = Settings.Tab.Wallpaper
        }
    }
}
