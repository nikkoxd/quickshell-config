import QtQuick
import QtQuick.Layouts
import qs.Core

Item {
    id: root
    implicitWidth: column.implicitWidth + 30
    implicitHeight: column.implicitHeight + 30
    required property string icon
    required property string text
    property string subText: ""
    property string leftButtonText: ""
    property string rightButtonText: ""
    property bool animated: false
    signal componentClicked
    signal leftButtonClicked
    signal rightButtonClicked

    TapHandler {
        onTapped: root.componentClicked()
    }

    HoverHandler {
        id: hover
    }

    Column {
        id: column
        spacing: 10
        anchors.centerIn: parent

        Row {
            spacing: 10

            ThemedText {
                text: root.icon
                icon: true
                font.pixelSize: Config.theme.fontSize * 1.75
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: root.animated
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.8
                        duration: 1200
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 0.5
                        duration: 1200
                        easing.type: Easing.InOutSine
                    }
                }

                RotationAnimation on rotation {
                    running: root.animated
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 3000
                    easing.type: Easing.InOutCubic
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                ThemedText {
                    text: root.text

                    SequentialAnimation on opacity {
                        running: root.animated
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.8
                            duration: 1200
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 0.5
                            duration: 1200
                            easing.type: Easing.InOutSine
                        }
                    }
                }
                ThemedText {
                    text: root.subText
                    visible: root.subText.length > 0
                    opacity: 0.5
                    font.pixelSize: Config.theme.fontSize * 0.8
                    SequentialAnimation on opacity {
                        running: root.animated
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.8
                            duration: 1200
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 0.5
                            duration: 1200
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            visible: hover.hovered
            spacing: 10

            Button {
                buttonText: root.leftButtonText
                onClicked: root.leftButtonClicked()
                visible: root.leftButtonText.length > 0
            }

            Button {
                buttonText: root.rightButtonText
                onClicked: root.rightButtonClicked()
                visible: root.rightButtonText.length > 0
            }

            component Button: Rectangle {
                id: button
                height: 30
                color: buttonHover.hovered ? Config.colorscheme.bgAlt : Config.colorscheme.bg
                radius: 10
                Layout.fillWidth: true
                required property string buttonText
                signal clicked

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

                ThemedText {
                    text: button.buttonText
                    anchors.centerIn: parent
                }

                HoverHandler {
                    id: buttonHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    gesturePolicy: TapHandler.WithinBounds
                    onTapped: button.clicked()
                }
            }
        }
    }
}
