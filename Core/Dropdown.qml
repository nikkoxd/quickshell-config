pragma ComponentBehavior: Bound

import QtQuick

// A single-select dropdown: a trigger showing the current choice, and a list
// that expands underneath it. The list floats — the root is only ever as tall
// as the trigger — so opening one never reflows the surrounding layout.
Item {
    id: root
    implicitWidth: headerLabel.implicitWidth + caret.implicitWidth + 8 + root.horizontalPadding * 2
    implicitHeight: 40
    z: 10

    // Accepts either plain strings or { label, value } pairs, matching
    // SegmentPill's option shape.
    property var options: []
    property var current
    property string placeholder: ""
    property real radius: 10
    property real horizontalPadding: 20
    property color backgroundColor: Config.colorscheme.surface
    property color hoverColor: Config.colorscheme.accentAlt

    signal selected(var value)

    readonly property bool expanded: root._expanded
    property bool _expanded: false

    // How far the open list reaches below the trigger. Containers that clip
    // (a View inside the island window) have to grow by this much.
    readonly property real listHeight: list.height + 8 + 4

    readonly property var entries: (root.options ?? []).map(option => typeof option === "string" ? ({
                label: option,
                value: option
            }) : option)

    function labelFor(value) {
        const match = root.entries.find(entry => entry.value === value);
        return match ? match.label : root.placeholder;
    }

    function collapse() {
        root._expanded = false;
    }

    // Item.enabled gates the handlers on its own; this only makes sure an
    // already-open list does not stay on screen when the trigger goes dead.
    onEnabledChanged: {
        if (!root.enabled)
            root._expanded = false;
    }

    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.height
        radius: root.radius
        color: headerHover.hovered || root._expanded ? root.hoverColor : root.backgroundColor

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }

        ThemedText {
            id: headerLabel
            anchors.left: parent.left
            anchors.right: caret.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: 4
            text: root.labelFor(root.current)
            elide: Text.ElideRight
        }

        ThemedText {
            id: caret
            anchors.right: parent.right
            anchors.rightMargin: root.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            icon: true
            text: root._expanded ? "caret-up" : "caret-down"
            opacity: root.enabled ? 1 : 0.3
        }

        HoverHandler {
            id: headerHover
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            gesturePolicy: TapHandler.WithinBounds
            onTapped: {
                if (root.enabled)
                    root._expanded = !root._expanded;
            }
        }
    }

    Rectangle {
        anchors.top: header.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: root._expanded ? list.height + 8 : 0
        clip: true
        radius: root.radius
        color: Config.colorscheme.surface
        opacity: root._expanded ? 1 : 0
        visible: opacity > 0

        Behavior on height {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: list
            y: 4
            width: parent.width
            spacing: 2

            Repeater {
                model: root.entries

                Rectangle {
                    id: entry
                    required property var modelData

                    readonly property bool active: modelData.value === root.current

                    width: list.width
                    height: 26
                    color: entryHover.hovered ? Config.colorscheme.accent : "transparent"
                    radius: root.radius

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }

                    ThemedText {
                        anchors.left: parent.left
                        anchors.right: check.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: root.horizontalPadding
                        anchors.rightMargin: 4
                        text: entry.modelData.label
                        elide: Text.ElideRight
                        color: entryHover.hovered ? Config.colorscheme.bg : Config.colorscheme.fg

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    ThemedText {
                        id: check
                        anchors.right: parent.right
                        anchors.rightMargin: root.horizontalPadding
                        anchors.verticalCenter: parent.verticalCenter
                        icon: true
                        text: "check"
                        visible: entry.active
                        color: entryHover.hovered ? Config.colorscheme.bg : Config.colorscheme.accent
                    }

                    HoverHandler {
                        id: entryHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        gesturePolicy: TapHandler.WithinBounds
                        onTapped: {
                            root.selected(entry.modelData.value);
                            root._expanded = false;
                        }
                    }
                }
            }
        }
    }
}
