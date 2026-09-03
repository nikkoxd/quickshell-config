import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Core

FloatingWindow {
    id: root
    color: Config.colorscheme.bg
    title: "Settings"
    // Floor under the sidebar plus a label and its control, so the pages are
    // never squeezed past what their layouts can shrink to.
    minimumSize: Qt.size(640, 400)

    property int currentTab: sidebar.currentTab

    enum Tab {
        Island,
        Dns,
        Dock,
        Launcher,
        Recording,
        Visualizer,
        Theme,
        Templates,
        Wallpaper
    }

    RowLayout {
        spacing: 30
        anchors.fill: parent
        anchors.margins: Config.island.padding

        SettingsSidebar {
            id: sidebar
        }

        SettingsIsland {
            visible: root.currentTab === Settings.Tab.Island
        }

        SettingsDns {
            visible: root.currentTab === Settings.Tab.Dns
        }

        SettingsDock {
            visible: root.currentTab === Settings.Tab.Dock
        }

        SettingsLauncher {
            visible: root.currentTab === Settings.Tab.Launcher
        }

        SettingsRecording {
            visible: root.currentTab === Settings.Tab.Recording
        }

        SettingsVisualizer {
            visible: root.currentTab === Settings.Tab.Visualizer
        }

        SettingsTheme {
            visible: root.currentTab === Settings.Tab.Theme
        }

        SettingsTemplates {
            visible: root.currentTab === Settings.Tab.Templates
        }

        SettingsWallpaper {
            visible: root.currentTab === Settings.Tab.Wallpaper
        }
    }
}
