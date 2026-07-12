import QtQuick
import Quickshell.Hyprland
import qs.Core

View {
    id: root
    implicitWidth: workspaces.implicitWidth + Config.island.padding * 2
    implicitHeight: Config.island.height

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            timer.restart();
        }
    }

    Timer {
        id: timer
        interval: 1000
        running: true
        onTriggered: {
            root.closeRequested();
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.LeftButton) {
                root.viewChangeRequested("dashboard");
            } else {
                root.viewChangeRequested("controlCenter");
            }
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                timer.running = false;
            } else {
                timer.running = true;
            }
        }
    }

    Item {
        id: wrapper
        width: workspaces.implicitWidth + Config.island.padding * 2
        height: Config.island.height
        anchors.centerIn: parent

        Row {
            id: workspaces
            spacing: 5
            anchors.centerIn: parent

            Repeater {
                model: Hyprland.workspaces

                ThemedText {
                    id: text
                    text: modelData.name
                    opacity: modelData.active ? 1 : 0.5
                    required property var modelData

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered) {
                                text.opacity = 1;
                            } else {
                                text.opacity = 0.5;
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onTapped: (eventPoint, button) => {

                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }
}
