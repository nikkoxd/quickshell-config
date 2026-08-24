import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.Core

Rectangle {
    id: notifEntry

    required property var modelData

    property real fullWidth: 310
    // Position inside a collapsed stack: 0 is the front card, deeper cards are
    // drawn as slivers peeking out below it.
    property int depth: 0
    property bool stacked: false
    // Shown as a pill on the front card of a collapsed stack.
    property int badgeCount: 0
    // Kept separate from `opacity` so the swipe gesture does not clobber the
    // binding that dims cards behind the front one.
    property real swipeOpacity: 1
    // Swipe offset, added on top of the resting `x` so the gesture never breaks
    // the binding that insets cards inside a stack. A collapsed stack is swiped
    // as a whole by NotificationGroup instead.
    property real swipeX: 0

    signal dismissRequested
    signal expandRequested

    readonly property real stackInset: 8
    // Cards behind the front one slide up under it by `stackOverlap` (see the
    // negative Column spacing in NotificationGroup) so only their
    // rounded bottom edge shows.
    readonly property real stackOverlap: radius
    readonly property real stackPeek: 6
    readonly property bool interactive: !stacked || depth === 0

    width: fullWidth - (stacked ? depth * stackInset * 2 : 0)
    x: (stacked ? depth * stackInset : 0) + swipeX
    height: stacked && depth > 0 ? stackOverlap + stackPeek : notifRow.implicitHeight + 20
    z: stacked ? -depth : 0
    visible: !stacked || depth < 3
    clip: true
    radius: Config.island.radius / 2
    topLeftRadius: stacked && depth > 0 ? 0 : radius
    topRightRadius: stacked && depth > 0 ? 0 : radius
    color: Config.colorscheme.surface
    opacity: swipeOpacity * (stacked && depth > 0 ? 0.7 : 1)

    Behavior on width {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: resetAnim
        NumberAnimation {
            target: notifEntry
            property: "swipeOpacity"
            to: 1
            duration: 100
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: notifEntry
            property: "swipeX"
            to: 0
            duration: 100
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: dismissAnim
        ParallelAnimation {
            NumberAnimation {
                target: notifEntry
                property: "swipeOpacity"
                to: 0
                duration: 100
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: notifEntry
                property: "scale"
                to: 0.9
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: notifEntry
                property: "swipeX"
                to: notifEntry.width
                duration: 100
                easing.type: Easing.OutQuad
            }
        }
        ScriptAction {
            script: {
                notifEntry.dismissRequested();
            }
        }
    }

    // A collapsed stack is dragged as a whole by the group, so this only runs for
    // standalone cards and for the cards of an expanded stack.
    DragHandler {
        enabled: !notifEntry.stacked
        target: null
        yAxis.enabled: false
        dragThreshold: 10
        onActiveChanged: {
            if (!active) {
                if (notifEntry.swipeX > notifEntry.width * 0.2) {
                    dismissAnim.restart();
                } else {
                    resetAnim.restart();
                }
            }
        }
        onActiveTranslationChanged: {
            notifEntry.swipeX = Math.max(0, activeTranslation.x);
            notifEntry.swipeOpacity = 1 - notifEntry.swipeX / (notifEntry.width * 0.8);
        }
    }

    TapHandler {
        enabled: notifEntry.interactive
        gesturePolicy: TapHandler.WithinBounds
        onTapped: (eventPoint, button) => {
            if (notifEntry.stacked) {
                notifEntry.expandRequested();
                return;
            }

            var defaultAction = notifEntry.modelData.actions.find(a => a.identifier === "default");
            if (defaultAction) {
                defaultAction.invoke();
                notifEntry.modelData.dismiss();
            }
        }
    }

    Row {
        id: notifRow
        spacing: 10
        anchors.fill: parent
        anchors.margins: 10
        // A sliver is only a few pixels tall, its content would bleed through.
        visible: !notifEntry.stacked || notifEntry.depth === 0

        IconImage {
            source: Quickshell.iconPath(notifEntry.modelData.appIcon, true)
            width: 35
            height: 35
            asynchronous: true
            visible: source.toString().length > 0
        }

        Column {
            spacing: 2

            ThemedText {
                text: notifEntry.modelData.appName
                font.pixelSize: 12
                opacity: 0.5
            }

            ScrollingText {
                text: notifEntry.modelData.summary
                maxWidth: notifEntry.badgeCount > 1 ? 205 : 240
            }

            ThemedText {
                text: notifEntry.modelData.body
                font.pixelSize: 12
                opacity: 0.5
                width: notifEntry.badgeCount > 1 ? 205 : 240
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        visible: notifEntry.badgeCount > 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        width: Math.max(20, badgeText.implicitWidth + 10)
        height: 20
        radius: height / 2
        color: Config.colorscheme.accent

        ThemedText {
            id: badgeText
            anchors.centerIn: parent
            text: notifEntry.badgeCount
            font.pixelSize: 11
            color: Config.colorscheme.bg
        }
    }
}
