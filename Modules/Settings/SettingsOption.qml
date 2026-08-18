pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
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
            background: Rectangle {
                anchors.fill: parent
                color: Config.colorscheme.surface
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
            id: switchControl
            visible: root.type === SettingsOption.Type.Switch
            checked: root.value
            onCheckedChanged: root.checked(checked)
            indicator: Rectangle {
                anchors.fill: parent
                anchors.margins: 7
                color: Config.colorscheme.surface
                radius: height

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                Rectangle {
                    x: switchControl.checked ? parent.width - width : 0
                    height: parent.height
                    width: parent.height
                    radius: parent.height
                    color: switchControl.checked ? Config.colorscheme.accent : Config.colorscheme.fg

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

        ComboBox {
            id: cboxControl
            visible: root.type === SettingsOption.Type.ComboBox
            model: root.options
            currentIndex: root.options ? root.options.indexOf(root.value) : -1
            onActivated: root.edited(currentText)
            indicator: Item {}
            contentItem: ThemedText {
                leftPadding: 20
                rightPadding: 20
                verticalAlignment: Text.AlignVCenter
                text: cboxControl.displayText
                font.pixelSize: 16
            }
            background: Rectangle {
                color: Config.colorscheme.surface
                radius: 10
            }
            popup: Popup {
                y: cboxControl.height + 5
                width: cboxControl.width
                height: contentItem.implicitHeight
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: cboxControl.popup.visible ? cboxControl.delegateModel : null
                    currentIndex: cboxControl.highlightedIndex
                    delegate: ItemDelegate {
                        id: cboxDelegate
                        required property var modelData
                        required property int index
                        width: cboxControl.width
                        height: 36
                        highlighted: cboxControl.highlightedIndex === index
                        contentItem: ThemedText {
                            text: cboxDelegate.modelData
                            font.pixelSize: 16
                            leftPadding: 20
                            rightPadding: 20
                            verticalAlignment: Text.AlignVCenter
                            color: cboxDelegate.highlighted ? Config.colorscheme.bg : Config.colorscheme.fg
                        }
                        background: Rectangle {
                            color: cboxDelegate.highlighted ? Config.colorscheme.accent : "transparent"
                            radius: 10
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
                background: Rectangle {
                    color: Config.colorscheme.surface
                    radius: 10
                }
            }
            Layout.preferredHeight: 40
            Layout.preferredWidth: 100
        }

        ThemedText {
            visible: root.units !== ""
            text: root.units
            font.pixelSize: 16
        }
    }
}
