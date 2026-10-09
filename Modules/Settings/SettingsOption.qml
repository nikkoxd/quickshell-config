pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Core

RowLayout {
    id: root

    property string title
    property var value
    property var options
    property string units: ""
    property int type: SettingsOption.Type.TextField
    // A text field with a unit holding a number steps through it on the mouse
    // wheel, `step` a notch (ten with Shift held), clamped to the range below.
    // Nearly every such value is a size or a duration, hence the floor of 0.
    property real step: 1
    property real minimum: 0
    property real maximum: Infinity
    readonly property bool scrollable: root.type === SettingsOption.Type.TextField && root.units !== "" && typeof root.value === "number"
    signal edited(string value)
    signal checked(bool checked)

    enum Type {
        TextField,
        Switch,
        ComboBox
    }

    // Wheel travel not yet worth a whole step; touchpads deliver a notch in
    // many small pieces.
    property real _wheel: 0

    function _display() {
        return root.value !== undefined ? root.value : "";
    }

    function _scroll(event) {
        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
        root._wheel += delta;
        const notches = Math.trunc(root._wheel / 120);
        if (notches === 0)
            return;
        root._wheel -= notches * 120;

        // Start from what is in the field, so a number typed but not yet
        // confirmed is stepped from rather than thrown away.
        const typed = parseFloat(field.text);
        const current = isNaN(typed) ? root.value : typed;
        const step = root.step * (event.modifiers & Qt.ShiftModifier ? 10 : 1);
        const next = Math.min(root.maximum, Math.max(root.minimum, current + notches * step));
        // Rounded to the step's own precision, so 0.1 steps don't drift into
        // 0.30000000000000004.
        const decimals = (String(root.step).split(".")[1] || "").length;
        root.edited(next.toFixed(decimals));
        // The binding only re-runs when the value changes, and stepping back to
        // the saved value from a typed one would not change it.
        field.text = Qt.binding(root._display);
    }

    Layout.fillWidth: true
    // A Dropdown raises itself above its own siblings, but its list still hangs
    // over the rows below, which are siblings of this whole row. Lift the row
    // itself while the list is open so it paints over them.
    z: dropdown.expanded ? 10 : 0

    ThemedText {
        text: root.title
        font.pixelSize: 16
        elide: Text.ElideRight
        Layout.preferredWidth: 200
        // Long titles keep their 200px slot, but give it up before the row is
        // forced wider than the window.
        Layout.minimumWidth: 60
        Layout.maximumWidth: 200
    }

    // Takes the leftover space so the controls stay right-aligned, and so a
    // TextField holding a long path stretches into this row instead of pushing
    // the whole page past the window edge.
    RowLayout {
        spacing: 10
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignRight

        // Pushes the control to the right edge; it also absorbs whatever the
        // TextField refuses above its maximum width.
        Item {
            Layout.fillWidth: true
        }

        TextField {
            id: field
            visible: root.type === SettingsOption.Type.TextField
            text: root._display()
            onEditingFinished: root.edited(text)
            suffix: root.units
            font.pixelSize: 16
            Layout.preferredHeight: 40
            // Sized by its content, but capped: the implicitWidth grows with the
            // text, and a wallpaper path is far wider than the window. Past the
            // cap the text scrolls inside the field instead.
            Layout.minimumWidth: 120
            Layout.maximumWidth: 400

            // A MouseArea rather than a WheelHandler: the page's ScrollArea is a
            // Flickable, which takes the wheel before a handler in here sees it.
            // Clicks still go through to the field.
            MouseArea {
                anchors.fill: parent
                enabled: root.scrollable
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.IBeamCursor
                onWheel: event => root._scroll(event)
            }
        }

        Toggle {
            visible: root.type === SettingsOption.Type.Switch
            checked: root.value
            onToggled: value => root.checked(value)
            Layout.preferredHeight: 40
            Layout.preferredWidth: 65
        }

        Dropdown {
            id: dropdown
            visible: root.type === SettingsOption.Type.ComboBox
            options: root.options
            current: root.value
            onSelected: value => root.edited(value)
            Layout.preferredHeight: 40
            // Same deal as the TextField: wide enough for its longest option,
            // but not wide enough to push the page off screen.
            Layout.minimumWidth: 150
            Layout.maximumWidth: 400
        }

        // Text fields carry the unit inside themselves; the other control types
        // still need it spelled out beside them.
        ThemedText {
            visible: root.units !== "" && root.type !== SettingsOption.Type.TextField
            text: root.units
            font.pixelSize: 16
        }
    }
}
