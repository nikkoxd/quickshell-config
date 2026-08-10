pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.Core

// Context menu drawn inside the dock's own window (the dock surface already
// covers the screen), so it needs no popup window or focus grab.
Item {
    id: root

    // [{ text: string, icon: Phosphor glyph name, triggered: function }]
    property var entries: []

    // Point the menu points at: the centre of the top edge of the dock icon.
    property real anchorCenterX: 0
    property real anchorTopY: 0

    implicitWidth: column.implicitWidth + 20
    implicitHeight: column.implicitHeight + 16
    visible: false

    // Bindings, not one-shot placement: the size only settles after the layout
    // has run, which is a frame later than the click.
    x: Math.max(8, Math.min((parent?.width ?? 0) - width - 8, anchorCenterX - width / 2))
    y: anchorTopY - height - 8

    function open(entries) {
        root.entries = entries;
        root.visible = true;
    }

    function close() {
        root.visible = false;
        root.entries = [];
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Config.colorscheme.bg
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#af1a1a1a"
            shadowVerticalOffset: 4
            shadowBlur: 0.6
            autoPaddingEnabled: true
        }

        // swallow clicks on the padding so they don't reach the close catcher
        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        }
    }

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.entries

            delegate: Rectangle {
                id: item

                required property var modelData

                Layout.fillWidth: true
                implicitWidth: row.implicitWidth + 16
                implicitHeight: row.implicitHeight + 8
                radius: 4
                color: itemHover.hovered ? Config.colorscheme.accent : "transparent"

                readonly property color contentColor: itemHover.hovered ? Config.colorscheme.bg : Config.colorscheme.fg

                Row {
                    id: row
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    ThemedText {
                        icon: true
                        text: item.modelData.icon ?? ""
                        visible: text !== ""
                        color: item.contentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ThemedText {
                        text: item.modelData.text
                        color: item.contentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler {
                    id: itemHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onTapped: (eventPoint, button) => {
                        if (button === Qt.LeftButton)
                            item.modelData.triggered();
                        root.close();
                    }
                }
            }
        }
    }
}
