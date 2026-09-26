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
        Notifications,
        Recording,
        Visualizer,
        Theme,
        Templates,
        Wallpaper,
        Widgets
    }

    RowLayout {
        spacing: 30
        anchors.fill: parent
        anchors.margins: Config.island.padding

        // The tab list outgrows a short window before the pages do, so it gets
        // the same treatment.
        ScrollArea {
            Layout.fillHeight: true
            Layout.preferredWidth: sidebar.implicitWidth + gutter

            SettingsSidebar {
                id: sidebar
            }
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Island
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsIsland {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Dns
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsDns {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Dock
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsDock {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Launcher
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsLauncher {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Notifications
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsNotifications {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Recording
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsRecording {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Visualizer
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsVisualizer {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Theme
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsTheme {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Templates
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsTemplates {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Wallpaper
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsWallpaper {}
        }

        ScrollArea {
            visible: root.currentTab === Settings.Tab.Widgets
            Layout.fillWidth: true
            Layout.fillHeight: true
            // A row is a 200px title, its spacing and the widest control
            // minimum (the Dropdown's 150px). Below that the page scrolls
            // sideways instead of squeezing its controls away.
            minContentWidth: 360

            SettingsWidgets {}
        }
    }
}
