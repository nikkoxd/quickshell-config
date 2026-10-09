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

    // Edits are only staged in SettingsDraft until this runs. A text field
    // hands its text over when it loses focus, so take focus away first or a
    // value still being typed would miss the save.
    function save() {
        saveButton.forceActiveFocus();
        SettingsDraft.save();
    }

    // Closing the window throws away whatever was not saved.
    Component.onDestruction: SettingsDraft.discard()

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

        // Inside the content rather than on the window: a Shortcut finds its
        // window through the item it sits in.
        Shortcut {
            sequence: "Ctrl+S"
            onActivated: root.save()
        }

        ColumnLayout {
            spacing: 10
            Layout.fillHeight: true
            // The save button fills its row, which would otherwise make this
            // whole column claim a share of the window's width.
            Layout.fillWidth: false
            Layout.preferredWidth: sidebar.implicitWidth + tabs.gutter

            // The tab list outgrows a short window before the pages do, so it
            // gets the same treatment.
            ScrollArea {
                id: tabs
                Layout.fillWidth: true
                Layout.fillHeight: true

                SettingsSidebar {
                    id: sidebar
                }
            }

            // Kept out of the scrolling list, so it stays in reach however
            // short the window is.
            RowLayout {
                spacing: 10
                Layout.fillWidth: false
                Layout.preferredWidth: sidebar.implicitWidth

                Rectangle {
                    id: saveButton
                    color: SettingsDraft.dirty ? (saveHover.hovered ? Config.colorscheme.accentAlt : Config.colorscheme.accent) : Config.colorscheme.surface
                    opacity: SettingsDraft.dirty ? 1 : 0.5
                    radius: 10
                    implicitHeight: 40
                    Layout.fillWidth: true

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }

                    HoverHandler {
                        id: saveHover
                        cursorShape: SettingsDraft.dirty ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }

                    TapHandler {
                        enabled: SettingsDraft.dirty
                        onTapped: root.save()
                    }

                    Row {
                        spacing: 10
                        anchors.centerIn: parent

                        ThemedText {
                            icon: true
                            text: "floppy-disk"
                            color: SettingsDraft.dirty ? Config.colorscheme.bg : Config.colorscheme.fg
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        ThemedText {
                            text: SettingsDraft.dirty ? "Save (" + SettingsDraft.count + ")" : "Saved"
                            color: SettingsDraft.dirty ? Config.colorscheme.bg : Config.colorscheme.fg
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                IconButton {
                    icon: "arrow-counter-clockwise"
                    opacity: SettingsDraft.dirty ? 1 : 0.3
                    implicitWidth: 40
                    implicitHeight: 40
                    onClicked: {
                        if (SettingsDraft.dirty)
                            SettingsDraft.discard();
                    }
                }
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
