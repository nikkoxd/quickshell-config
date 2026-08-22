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
        Layout.preferredWidth: 200
    }

    Item {
        Layout.fillWidth: true
    }

    RowLayout {
        spacing: 10

        TextField {
            visible: root.type === SettingsOption.Type.TextField
            text: root.value !== undefined ? root.value : ""
            onEditingFinished: root.edited(text)
            font.pixelSize: 16
            Layout.preferredHeight: 40
            Layout.minimumWidth: 60
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
            Layout.preferredWidth: 150
        }

        ThemedText {
            visible: root.units !== ""
            text: root.units
            font.pixelSize: 16
        }
    }
}
