import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.Core

Rectangle {
    id: notifEntry
    width: Math.max(list.width, notifRow.implicitWidth + 20)
    height: notifRow.implicitHeight + 20
    radius: Config.island.radius / 2
    color: Config.colorscheme.bgAlt
    required property var modelData

    ParallelAnimation {
        id: resetAnim
        NumberAnimation {
            target: notifEntry
            property: "opacity"
            to: 1
            duration: 100
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: notifEntry
            property: "x"
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
                property: "opacity"
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
                property: "x"
                to: notifEntry.width
                duration: 100
                easing.type: Easing.OutQuad
            }
        }
        ScriptAction {
            script: {
                notifEntry.modelData.dismiss();
            }
        }
    }

    DragHandler {
        xAxis.minimum: 0
        yAxis.enabled: false
        dragThreshold: 10
        onActiveChanged: {
            if (!active) {
                if (Math.abs(notifEntry.x) > notifEntry.width * 0.2) {
                    dismissAnim.running = true;
                } else {
                    resetAnim.running = true;
                }
            }
        }
        onTranslationChanged: {
            notifEntry.opacity = 1 - Math.abs(notifEntry.x) / (notifEntry.width * 0.8);
        }
    }

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        onTapped: (eventPoint, button) => {
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
                maxWidth: 240
            }

            ThemedText {
                text: notifEntry.modelData.body
                font.pixelSize: 12
                opacity: 0.5
                width: 240
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }
}
