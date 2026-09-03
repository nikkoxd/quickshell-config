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
    signal edited(string value)
    signal checked(bool checked)

    enum Type {
        TextField,
        Switch,
        ComboBox
    }

    Layout.fillWidth: true

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
            visible: root.type === SettingsOption.Type.TextField
            text: root.value !== undefined ? root.value : ""
            onEditingFinished: root.edited(text)
            suffix: root.units
            font.pixelSize: 16
            Layout.preferredHeight: 40
            // Sized by its content, but capped: the implicitWidth grows with the
            // text, and a wallpaper path is far wider than the window. Past the
            // cap the text scrolls inside the field instead.
            Layout.minimumWidth: 120
            Layout.maximumWidth: 400
        }

        Toggle {
            visible: root.type === SettingsOption.Type.Switch
            checked: root.value
            onToggled: value => root.checked(value)
            Layout.preferredHeight: 40
            Layout.preferredWidth: 65
        }

        Dropdown {
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
