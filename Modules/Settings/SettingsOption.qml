import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core

RowLayout {
    id: root

    property string title
    property var value
    property string units: ""
    property int type: SettingsOption.Type.TextField
    signal edited(string value)
    signal checked(bool checked)

    enum Type {
        TextField,
        Switch
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
            background: Rectangle {
                anchors.fill: parent
                color: Config.colorscheme.bgAlt
                radius: 10
            }
            color: Config.colorscheme.fg
            selectionColor: Config.colorscheme.accent
            selectedTextColor: Config.colorscheme.bg
            font.family: Config.theme.fontFamily
            font.pixelSize: 16
            leftPadding: 20
            rightPadding: 20
            Layout.preferredHeight: 40
            Layout.minimumWidth: 60
        }

        Switch {
            id: control
            visible: root.type === SettingsOption.Type.Switch
            checked: root.value
            onCheckedChanged: root.checked(checked)
            indicator: Rectangle {
                anchors.fill: parent
                anchors.margins: 7
                color: Config.colorscheme.bgAlt
                radius: height

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                Rectangle {
                    x: control.checked ? parent.width - width : 0
                    height: parent.height
                    width: parent.height
                    radius: parent.height
                    color: control.checked ? Config.colorscheme.accent : Config.colorscheme.fg

                    Behavior on x {
                        NumberAnimation {
                            duration: 150
                            easing: Easing.OutQuart
                        }
                    }
                }
            }
            Layout.preferredHeight: 40
            Layout.preferredWidth: 65
        }

        ThemedText {
            visible: root.units !== ""
            text: root.units
            font.pixelSize: 16
        }
    }
}
