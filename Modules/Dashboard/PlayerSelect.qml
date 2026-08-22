pragma ComponentBehavior: Bound

import QtQuick
import qs.Core
import qs.Services

Item {
    id: root
    height: header.height
    z: 10

    property bool expanded: false
    readonly property var players: MprisService.players.values

    function label(player) {
        if (!player)
            return "No player";
        return player.identity || player.trackTitle || "Unknown player";
    }

    // A player disappearing while the list is open would leave a stale dropdown.
    onPlayersChanged: {
        if (root.players.length < 2)
            root.expanded = false;
    }

    Rectangle {
        id: header
        width: parent.width
        height: 28
        radius: Config.island.radius / 2
        color: headerHover.hovered || root.expanded ? Config.colorscheme.surface : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }

        ThemedText {
            id: headerText
            anchors.left: parent.left
            anchors.right: caret.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 8
            anchors.rightMargin: 4
            text: root.label(MprisService.activePlayer)
            elide: Text.ElideRight
        }

        ThemedText {
            id: caret
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            icon: true
            text: root.expanded ? "caret-up" : "caret-down"
            opacity: root.players.length > 1 ? 1 : 0.3
        }

        HoverHandler {
            id: headerHover
            cursorShape: root.players.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            gesturePolicy: TapHandler.WithinBounds
            onTapped: {
                if (root.players.length > 1)
                    root.expanded = !root.expanded;
            }
        }
    }

    Rectangle {
        id: dropdown
        anchors.top: header.bottom
        anchors.topMargin: 4
        width: parent.width
        height: root.expanded ? list.height + 8 : 0
        clip: true
        radius: Config.island.radius / 2
        color: Config.colorscheme.surface
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        Behavior on height {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: list
            y: 4
            width: parent.width
            spacing: 2

            Repeater {
                model: root.players

                Rectangle {
                    id: entry
                    required property var modelData

                    readonly property bool active: modelData === MprisService.activePlayer

                    width: list.width
                    height: 26
                    color: entryHover.hovered ? Config.colorscheme.accent : "transparent"
                    radius: Config.island.radius / 2

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }

                    ThemedText {
                        anchors.left: parent.left
                        anchors.right: check.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        text: root.label(entry.modelData)
                        elide: Text.ElideRight
                        color: entryHover.hovered ? Config.colorscheme.bg : Config.colorscheme.fg
                    }

                    ThemedText {
                        id: check
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        icon: true
                        text: "check"
                        visible: entry.active
                        color: entryHover.hovered ? Config.colorscheme.bg : Config.colorscheme.accent
                    }

                    HoverHandler {
                        id: entryHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        gesturePolicy: TapHandler.WithinBounds
                        onTapped: {
                            MprisService.selectPlayer(entry.modelData);
                            root.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
