import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Services

WlSessionLockSurface {
    id: root

    required property LockscreenContext context
    property bool revealed: false
    property int slideDistance: 80

    function wake() {
        root.revealed = true;
        idleTimer.restart();
    }

    Timer {
        id: idleTimer
        interval: 10000
        repeat: false
        onTriggered: root.revealed = false
    }

    ScreencopyView {
        id: background
        anchors.fill: parent
        captureSource: root.screen
        opacity: 1
    }

    LockscreenWallpaper {
        anchors.fill: parent
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Config.colorscheme.bg
        opacity: root.revealed ? 0.7 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuart
            }
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: root.revealed ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuart
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 600

            ColumnLayout {
                id: top
                Layout.alignment: Qt.AlignHCenter

                transform: Translate {
                    y: root.revealed ? 0 : -root.slideDistance

                    Behavior on y {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.InOutQuart
                        }
                    }
                }

                ThemedText {
                    text: DateService.hours + ":" + DateService.minutes
                    font.pixelSize: 64
                    Layout.alignment: Qt.AlignHCenter
                }

                ThemedText {
                    text: DateService.date
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                id: bottom
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                transform: Translate {
                    y: root.revealed ? 0 : root.slideDistance

                    Behavior on y {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.InOutQuart
                        }
                    }
                }

                TextField {
                    focus: true
                    Keys.onPressed: root.wake()
                    Keys.onEscapePressed: {
                        root.revealed = false
                        root.context.currentText = ""
                    }
                    onTextChanged: root.context.currentText = text
                    onAccepted: root.context.tryUnlock()
                    implicitWidth: 300
                    implicitHeight: 40
                    padding: 10
                    leftPadding: 15
                    rightPadding: 15
                    color: Config.colorscheme.fg
                    font.family: Config.theme.fontFamily
                    font.pixelSize: 14
                    echoMode: TextField.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    placeholderText: "Password"
                    placeholderTextColor: Config.colorscheme.fg
                    background: Rectangle {
                        color: Config.colorscheme.bg
                        radius: height / 2
                    }
                }
            }
        }
    }

    // HoverHandler {
    //     onPointChanged: root.wake()
    // }

    TapHandler {
        onTapped: root.wake()
    }
}
