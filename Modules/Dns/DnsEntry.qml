import QtQuick
import qs.Core

Rectangle {
    id: root

    required property var entry
    required property bool current
    property bool busy: false

    signal activated

    height: 60
    radius: Config.island.radius
    color: hover.hovered ? Config.colorscheme.accent : Config.colorscheme.surface
    opacity: root.busy ? 0.5 : 1

    readonly property string subtitle: {
        const addresses = (root.entry.ipv4 || []).concat(root.entry.ipv6 || []).filter(a => a !== "");
        if (addresses.length === 0)
            return "Servers from DHCP";
        return addresses.join(", ");
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    HoverHandler {
        id: hover
        enabled: !root.busy
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: !root.busy
        onTapped: root.activated()
    }

    Column {
        anchors.left: parent.left
        anchors.right: check.left
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        ThemedText {
            width: parent.width
            elide: Text.ElideRight
            text: root.entry.name
            color: hover.hovered ? Config.colorscheme.bg : Config.colorscheme.fg

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ThemedText {
            width: parent.width
            elide: Text.ElideRight
            opacity: 0.5
            text: root.subtitle
            color: hover.hovered ? Config.colorscheme.bg : Config.colorscheme.fg

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    ThemedText {
        id: check
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        icon: true
        visible: root.current
        text: "check-circle"
        font.pixelSize: 18
        color: hover.hovered ? Config.colorscheme.bg : Config.colorscheme.fg

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }
    }
}
