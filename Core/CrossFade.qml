import QtQuick

// Fade-and-scale wrapper for an element that shares a slot with others: the
// default view's centre, or the artwork and the inline visualizer beside it.
//
// Only one member of a slot is `shown` at a time, and the two overlap for the
// length of the animation, so it is the element that changes rather than the
// space around it. Nothing here touches the layout — whoever owns the slot
// sizes it.
//
// `pop` is the overshoot past full size that reads as arriving out of nothing.
// It is wrong for a swap, where something else is already on its way out of the
// same spot, so it stays off unless asked for; PopIn turns it on.
Item {
    id: root

    // The visibility condition the wrapped element would otherwise apply.
    property bool shown: true

    property bool pop: false

    property int duration: 200

    default property alias content: holder.data

    readonly property Item item: holder.children.length > 0 ? holder.children[0] : null

    implicitWidth: root.item ? root.item.width : 0
    implicitHeight: root.item ? root.item.height : 0

    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : 0.8
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.OutQuad
        }
    }

    // OutBack overshoots a little past 1, which is the pop itself. OutCubic is
    // the same motion with the overshoot taken out.
    Behavior on scale {
        NumberAnimation {
            duration: root.duration + (root.pop ? 120 : 100)
            easing.type: root.pop ? Easing.OutBack : Easing.OutCubic
        }
    }

    Item {
        id: holder
        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight
    }
}
