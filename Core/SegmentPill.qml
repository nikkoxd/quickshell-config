pragma ComponentBehavior: Bound
import QtQuick

// Segmented control: a row of labels with a rounded highlight that slides onto
// the selected one. `options` is a list of { label, value } objects.
Rectangle {
    id: root

    property var options: []
    property var current
    property int horizontalPadding: 16
    property int verticalPadding: 8
    signal selected(var value)

    readonly property int currentIndex: {
        const list = options || [];
        for (let i = 0; i < list.length; i++) {
            if (list[i].value === current) {
                return i;
            }
        }
        return -1;
    }

    implicitWidth: row.width
    implicitHeight: row.height
    radius: height / 2
    color: Config.colorscheme.surface

    onCurrentIndexChanged: _sync()
    Component.onCompleted: _sync()

    // The highlight follows the selected segment's geometry, which only exists
    // once the repeater has laid out, so it is pushed instead of bound.
    function _sync() {
        const item = repeater.itemAt(root.currentIndex);
        highlight.visible = item !== null;
        if (!item) {
            return;
        }

        highlight.x = item.x;
        highlight.width = item.width;
        Qt.callLater(() => highlight.ready = true);
    }

    Rectangle {
        id: highlight
        visible: false
        height: parent.height
        radius: height / 2
        color: Config.colorscheme.accent

        // Off until the first placement so the pill does not slide in from 0.
        property bool ready: false

        Behavior on x {
            enabled: highlight.ready
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            enabled: highlight.ready
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: row

        Repeater {
            id: repeater
            model: root.options

            Item {
                id: segment
                required property var modelData

                width: label.implicitWidth + root.horizontalPadding * 2
                height: label.implicitHeight + root.verticalPadding * 2

                onWidthChanged: root._sync()
                onXChanged: root._sync()

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.selected(segment.modelData.value)
                }

                ThemedText {
                    id: label
                    anchors.centerIn: parent
                    text: segment.modelData.label
                    color: root.current === segment.modelData.value ? Config.colorscheme.bg : Config.colorscheme.fg

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }
}
