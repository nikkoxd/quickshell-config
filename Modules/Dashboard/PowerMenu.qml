pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.Core

// The dashboard's power controls. A session rarely ends from here, so the row
// spends one button on it and expands into the individual actions on click
// instead of standing four destructive buttons in the open.
//
// The actions run the same commands as the launcher's default provider, so
// both routes end a session identically.
Row {
    id: root
    spacing: 0

    signal closeRequested

    property int size: 36
    property int gap: 8

    // Width the expanded row should come to, so the seam between it and
    // whatever follows lands on a column edge above it rather than a few
    // pixels off one. The options take up the slack between them; 0 leaves
    // them at `gap` like any other row.
    property int expandedWidth: 0

    // Negative spacing would overlap the buttons, so a target too small to
    // hold them just gives the natural row back.
    readonly property real optionSpacing: {
        const count = root.actions.length;
        if (root.expandedWidth <= 0)
            return root.gap;
        return Math.max(root.gap, (root.expandedWidth - root.size - root.gap - count * root.size) / (count - 1));
    }

    // Owned here rather than by the dashboard: nothing outside needs to know,
    // and the view is rebuilt on every open, so it starts collapsed for free.
    property bool expanded: false

    readonly property var actions: [
        {
            icon: "lock",
            command: ["loginctl", "lock-session"]
        },
        {
            icon: "moon",
            command: ["systemctl", "suspend"]
        },
        {
            icon: "arrows-clockwise",
            command: ["systemctl", "reboot"]
        },
        {
            icon: "power",
            command: ["systemctl", "poweroff"]
        }
    ]

    IconButton {
        implicitWidth: root.size
        implicitHeight: root.size
        icon: "power"
        // Expanded reads as a state of this button, so it takes the accent
        // fill and turns into the way back out.
        active: root.expanded
        activeIcon: "caret-left"
        onClicked: root.expanded = !root.expanded
    }

    // One clipped slot rather than a wrapper per button: four slots animating
    // their own width still owe the Row their spacing until each is dropped
    // from the layout, so collapsing ended in a jump as that spacing went at
    // once. Here the gap before the first option is inside the slot too, so
    // the whole thing is a single width to animate down to nothing.
    Item {
        id: options
        clip: true
        implicitWidth: root.expanded ? optionsRow.implicitWidth + root.gap : 0
        implicitHeight: root.size

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: optionsRow
            x: root.gap
            spacing: root.optionSpacing

            Repeater {
                model: root.actions

                IconButton {
                    id: button
                    required property var modelData

                    implicitWidth: root.size
                    implicitHeight: root.size
                    icon: button.modelData.icon
                    onClicked: {
                        Quickshell.execDetached(button.modelData.command);
                        root.closeRequested();
                    }
                }
            }
        }
    }
}
