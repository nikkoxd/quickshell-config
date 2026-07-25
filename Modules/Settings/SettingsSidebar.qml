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
            selected: root.currentTab === Settings.Tab.Island
            onTapped: root.currentTab = Settings.Tab.Island
        }

        SettingsTab {
            text: "Launcher"
            selected: root.currentTab === Settings.Tab.Launcher
            onTapped: root.currentTab = Settings.Tab.Launcher
        }

        SettingsTab {
            text: "Visualizer"
            selected: root.currentTab === Settings.Tab.Visualizer
            onTapped: root.currentTab = Settings.Tab.Visualizer
        }

        SettingsTab {
            text: "Theme"
            selected: root.currentTab === Settings.Tab.Theme
            onTapped: root.currentTab = Settings.Tab.Theme
        }

        SettingsTab {
            text: "Wallpaper"
            selected: root.currentTab === Settings.Tab.Wallpaper
            onTapped: root.currentTab = Settings.Tab.Wallpaper
        }
    }
}
