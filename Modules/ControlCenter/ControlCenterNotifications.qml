import QtQuick
import qs.Services

Column {
    id: root

    spacing: 5
    visible: NotificationService.groups.length > 0

    required property int contentHeight

    property var expandedApps: ({})

    function setExpanded(appName, value) {
        var next = Object.assign({}, expandedApps);
        if (value)
            next[appName] = true;
        else
            delete next[appName];
        expandedApps = next;
    }

    ListView {
        id: list
        clip: true
        width: 310
        height: root.contentHeight
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
        delegate: ControlCenterNotificationGroup {
            fullWidth: list.width
            expanded: root.expandedApps[modelData.appName] === true
            onExpandRequested: root.setExpanded(modelData.appName, true)
            onCollapseRequested: root.setExpanded(modelData.appName, false)
        }
    }
}
