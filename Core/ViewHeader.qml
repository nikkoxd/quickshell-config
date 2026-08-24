import QtQuick

// Title row shared by every non-default view: the view's name on the left, an
// optional slot for toggles on the right. Children go into that slot.
Item {
    id: root

    property string text
    default property alias actions: actionRow.data

    implicitWidth: label.implicitWidth + actionRow.implicitWidth + 10
    implicitHeight: Math.max(label.implicitHeight, actionRow.implicitHeight)

    ThemedText {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        isHeading: true
    }

    Row {
        id: actionRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
    }
}
