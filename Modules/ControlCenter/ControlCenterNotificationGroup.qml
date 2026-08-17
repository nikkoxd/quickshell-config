import QtQuick
import qs.Core
import qs.Services

Item {
    id: group

    // { appName, notifications: [newest, ..., oldest] }
    required property var modelData

    property bool expanded: false
    property real fullWidth: 310

    signal expandRequested
    signal collapseRequested

    readonly property var notifications: modelData.notifications
    readonly property int count: notifications.length
    readonly property bool stacked: count > 1 && !expanded
    // Pulls the cards behind the front one up under it, hiding their square top
    // edge so only the rounded bottom peeks out.
    readonly property real stackOverlap: Config.island.radius / 2

    // Swipe state of a collapsed stack. It lives on the group rather than on the
    // front card so every card in the stack travels with the gesture.
    property real swipeX: 0
    property real swipeOpacity: 1

    onStackedChanged: {
        if (!stacked) {
            swipeX = 0;
            swipeOpacity = 1;
        }
    }

    width: fullWidth
    // No Behavior here: the cards, the header and the Column spacing all animate
    // on their own, and smoothing this on top of that makes the height settle
    // well after those animations end (which the expand pin in
    // ControlCenterNotifications waits on).
    height: column.implicitHeight

    DragHandler {
        enabled: group.stacked
        target: null
        yAxis.enabled: false
        dragThreshold: 10
        onActiveChanged: {
            if (!active) {
                if (group.swipeX > group.width * 0.2)
                    stackDismissAnim.restart();
                else
                    stackResetAnim.restart();
            }
        }
        onActiveTranslationChanged: {
            group.swipeX = Math.max(0, activeTranslation.x);
            group.swipeOpacity = 1 - group.swipeX / (group.width * 0.8);
        }
    }

    ParallelAnimation {
        id: stackResetAnim
        NumberAnimation {
            target: group
            property: "swipeX"
            to: 0
            duration: 100
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: group
            property: "swipeOpacity"
            to: 1
            duration: 100
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: stackDismissAnim
        ParallelAnimation {
            NumberAnimation {
                target: group
                property: "swipeX"
                to: group.width
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: group
                property: "swipeOpacity"
                to: 0
                duration: 100
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: column
                property: "scale"
                to: 0.9
                duration: 100
                easing.type: Easing.OutQuad
            }
        }
        ScriptAction {
            script: NotificationService.dismissGroup(group.modelData.appName)
        }
    }

    Column {
        id: column
        width: parent.width
        x: group.swipeX
        opacity: group.swipeOpacity
        spacing: group.expanded ? 5 : (group.stacked ? -group.stackOverlap : 0)

        Behavior on spacing {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: header
            width: parent.width
            height: group.expanded && group.count > 1 ? 22 : 0
            opacity: group.expanded && group.count > 1 ? 1 : 0
            // Hidden entirely when collapsed, otherwise the Column would apply
            // the negative stack spacing above the front card.
            visible: height > 0
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            // Tapping the label area collapses the stack. It stops short of the
            // buttons so the two tap targets never overlap.
            Item {
                anchors.left: parent.left
                anchors.right: buttons.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    ThemedText {
                        text: group.modelData.appName
                        font.pixelSize: 12
                        opacity: 0.5
                    }

                    ThemedText {
                        text: group.count
                        font.pixelSize: 12
                        opacity: 0.3
                    }
                }

                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: group.collapseRequested()
                }
            }

            Row {
                id: buttons
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 2

                // The glyphs carry their own hit area: a bare Text is as tall as the
                // header itself, so taps land beside it as often as on it.
                Item {
                    width: 22
                    height: parent.height

                    ThemedText {
                        anchors.centerIn: parent
                        icon: true
                        text: "x-circle"
                        font.pixelSize: 14
                        opacity: clearHover.hovered ? 1 : 0.5
                    }

                    HoverHandler {
                        id: clearHover
                    }

                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: NotificationService.dismissGroup(group.modelData.appName)
                    }
                }

                Item {
                    width: 22
                    height: parent.height

                    ThemedText {
                        anchors.centerIn: parent
                        icon: true
                        text: "caret-up"
                        font.pixelSize: 14
                        opacity: collapseHover.hovered ? 1 : 0.5
                    }

                    HoverHandler {
                        id: collapseHover
                    }

                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: group.collapseRequested()
                    }
                }
            }
        }

        Repeater {
            model: group.notifications

            delegate: ControlCenterNotification {
                required property int index

                fullWidth: group.fullWidth
                depth: index
                stacked: group.stacked
                badgeCount: group.stacked && index === 0 ? group.count : 0
                onExpandRequested: group.expandRequested()
                onDismissRequested: modelData.dismiss()
            }
        }
    }
}
