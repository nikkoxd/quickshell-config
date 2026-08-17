pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    id: root

    property string title
    property var values: []
    property string placeholder: ""

    // Emitted with the whole new list; the page assigns it back to Config.
    signal updated(var values)

    function _set(index, value) {
        const next = Array.from(root.values);
        next[index] = value;
        root.updated(next);
    }

    function _remove(index) {
        const next = Array.from(root.values);
        next.splice(index, 1);
        root.updated(next);
    }

    function _add() {
        const next = Array.from(root.values);
        next.push("");
        root.updated(next);
    }

    spacing: 10
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true

        ThemedText {
            text: root.title
            font.pixelSize: 16
            Layout.preferredWidth: 200
        }

        Item {
            Layout.fillWidth: true
        }

        ThemedText {
            icon: true
            text: "plus-circle"
            font.pixelSize: 18
            color: addHover.hovered ? Config.colorscheme.accent : Config.colorscheme.fg

            HoverHandler {
                id: addHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root._add()
            }
        }
    }

    Repeater {
        model: root.values

        RowLayout {
            id: entry

            required property int index
            required property string modelData

            spacing: 10
            Layout.fillWidth: true

            TextField {
                text: entry.modelData
                placeholderText: root.placeholder
                onEditingFinished: root._set(entry.index, text)
                background: Rectangle {
                    anchors.fill: parent
                    color: Config.colorscheme.surface
                    radius: 10
                }
                color: Config.colorscheme.fg
                placeholderTextColor: Qt.alpha(Config.colorscheme.fg, 0.5)
                selectionColor: Config.colorscheme.accent
                selectedTextColor: Config.colorscheme.bg
                font.family: Config.theme.fontFamily
                font.pixelSize: 16
                leftPadding: 20
                rightPadding: 20
                Layout.preferredHeight: 40
                Layout.fillWidth: true
            }

            ThemedText {
                icon: true
                text: "x-circle"
                font.pixelSize: 18
                color: removeHover.hovered ? Config.colorscheme.accent : Config.colorscheme.fg

                HoverHandler {
                    id: removeHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root._remove(entry.index)
                }
            }
        }
    }
}
