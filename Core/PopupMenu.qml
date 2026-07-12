pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import qs.Core

PopupWindow {
    id: root
    visible: false
    implicitWidth: background.width + 20
    implicitHeight: background.height + 20
    color: "transparent"
    grabFocus: true
    mask: Region {
        item: background
    }

    required property var menu

    signal closeRequested()

    Rectangle {
        id: background
        height: content.height + 20
        width: content.width + 20
        color: Config.colorscheme.bg
        radius: 4
        anchors.centerIn: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.5
        }
    }

    Item {
        id: content
        anchors.top: background.top
        anchors.left: background.left
        anchors.margins: 10
        width: childrenRect.width
        height: childrenRect.height

        Column {
            id: column
            spacing: 5

            Repeater {
                model: root.menu

                Item {
                    id: itemContainer
                    width: itemContent.width + 10
                    height: itemContent.height + 2
                    required property var modelData

                    Rectangle {
                        id: itemBackground
                        width: parent.width
                        height: parent.height
                        color: Config.colorscheme.accent
                        opacity: 0
                        radius: 4

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    ThemedText {
                        id: itemContent
                        text: itemContainer.modelData.isSeparator ? "-" : itemContainer.modelData.text
                        anchors.centerIn: parent
                        anchors.margins: 5

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    TapHandler {
                        enabled: !itemContainer.modelData.isSeparator
                        onTapped: (eventPoint, button) => {
                            if (button === Qt.LeftButton) {
                                itemContainer.modelData.triggered();
                                root.closeRequested();
                                root.visible = false;
                            }
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        enabled: !itemContainer.modelData.isSeparator
                        onHoveredChanged: {
                            if (hovered) {
                                itemBackground.opacity = 1;
                                itemContent.color = Config.colorscheme.bg;
                            } else {
                                itemBackground.opacity = 0;
                                itemContent.color = Config.colorscheme.fg;
                            }
                        }
                    }
                }
            }
        }
    }

    function showMenu() {
        root.visible = true;
    }
}
