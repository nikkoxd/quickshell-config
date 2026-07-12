import QtQuick
import qs.Core

Item {
    id: root
    width: parent.width
    implicitHeight: row.implicitHeight + 10
    property bool hovered: hoverHandler.hovered
    required property var modelData
    function deviceTypeToIcon(type) {
        // mobile | desktop | web | headless | server, nullable
        switch (type) {
        case "mobile":
            return "mobile";
        case "desktop":
            return "desktop_windows";
        case "web":
            return "web";
        case "headless":
            return "terminal";
        case "server":
            return "database";
        default:
            return "help";
        }
    }
    signal clicked()

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Config.colorscheme.fg
        opacity: root.hovered ? 0.2 : 0
        radius: 5
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Row {
        id: row
        spacing: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        ThemedText {
            id: icon
            text: root.deviceTypeToIcon(root.modelData.deviceType)
            icon: true
            color: Config.colorscheme.accent
            font.pixelSize: Config.theme.fontSize * 1.5
            antialiasing: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            ThemedText {
                text: root.modelData.alias
            }
            ThemedText {
                text: root.modelData.ip
                opacity: 0.5
                font.pixelSize: Config.theme.fontSize * 0.8
            }
        }
    }

    ThemedText {
        text: "arrow_right_alt"
        icon: true
        anchors.right: row.right
        anchors.verticalCenter: row.verticalCenter
    }
}
