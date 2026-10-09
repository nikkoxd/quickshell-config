pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
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
        radius: 8
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
        width: column.implicitWidth
        height: column.implicitHeight

        // Laid out like the dock's menu: entries stretch to the widest one, so
        // the hover fill and the separators span the whole menu.
        ColumnLayout {
            id: column
            anchors.fill: parent
            spacing: 2

            Repeater {
                model: root.menu

                delegate: Rectangle {
                    id: item

                    required property var modelData
                    readonly property bool separator: modelData.isSeparator ?? false
                    // Plain JS entries carry no enabled flag; tray entries do.
                    readonly property bool active: !separator && (modelData.enabled ?? true)

                    Layout.fillWidth: true
                    implicitWidth: separator ? 0 : row.implicitWidth + 16
                    implicitHeight: separator ? 9 : row.implicitHeight + 8
                    radius: 4
                    color: itemHover.hovered && item.active ? Config.colorscheme.accent : "transparent"

                    readonly property color contentColor: itemHover.hovered && item.active ? Config.colorscheme.bg : Config.colorscheme.fg

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Rectangle {
                        visible: item.separator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 4
                        height: 1
                        color: Config.colorscheme.fg
                        opacity: 0.15
                    }

                    Row {
                        id: row
                        visible: !item.separator
                        opacity: item.active ? 1 : 0.5
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Tray entries hand over a resolved image path.
                        IconImage {
                            visible: source != ""
                            implicitSize: Config.theme.fontSize * 1.2
                            source: item.modelData.icon ?? ""
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        ThemedText {
                            text: item.modelData.text ?? ""
                            color: item.contentColor
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }

                    HoverHandler {
                        id: itemHover
                        enabled: item.active
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: item.active
                        onTapped: (eventPoint, button) => {
                            if (button === Qt.LeftButton) {
                                item.modelData.triggered();
                                root.closeRequested();
                                root.visible = false;
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
