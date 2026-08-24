import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: column.implicitWidth + Config.island.padding
    implicitHeight: column.implicitHeight + Config.island.padding
    focused: true
    dismissable: false
    displayInFullscreen: true
    closeOnUnhover: true

    // The list keeps this height whether or not anything is in it, so the island
    // does not resize under the pointer as notifications come and go.
    readonly property int contentHeight: 220
    readonly property int contentWidth: 310

    property var expandedApps: ({})

    function setExpanded(appName, value) {
        var next = Object.assign({}, expandedApps);
        if (value)
            next[appName] = true;
        else
            delete next[appName];
        expandedApps = next;
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.viewChangeRequested("dashboard")
    }

    Column {
        id: column
        anchors.centerIn: parent
        spacing: Config.island.padding / 4

        ViewHeader {
            width: root.contentWidth
            text: "Notifications"

            IconButton {
                icon: "bell"
                activeIcon: "bell-slash"
                active: NotificationService.muted
                onClicked: NotificationService.muted = !NotificationService.muted
            }
        }

        Item {
            width: root.contentWidth
            height: root.contentHeight

            ThemedText {
                anchors.centerIn: parent
                text: "No notifications"
                opacity: 0.5
                visible: NotificationService.groups.length === 0
            }

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 5
                model: NotificationService.groups
                verticalLayoutDirection: ListView.TopToBottom
                highlightFollowsCurrentItem: false
                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 0.9
                        to: 1
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
                delegate: NotificationGroup {
                    fullWidth: list.width
                    expanded: root.expandedApps[modelData.appName] === true
                    onExpandRequested: root.setExpanded(modelData.appName, true)
                    onCollapseRequested: root.setExpanded(modelData.appName, false)
                }
            }
        }
    }
}
