import QtQuick

// Grow-and-shrink wrapper for the default view's ambient indicators.
//
// An indicator that simply flips `visible` arrives at full size in one frame and
// drags the island's width along with it. Wrapped here, the slot it occupies in
// the Row animates open and shut while the indicator scales and fades inside it,
// so arriving and leaving each read as a single motion.
//
// The child must not hide itself: its condition belongs on `shown` here, because
// the wrapper still needs something laid out to animate on the way out.
Item {
    id: root

    // The visibility condition the wrapped indicator would otherwise apply.
    property bool shown: true

    // Pop in on creation rather than starting open. For indicators built from a
    // model, where being constructed is the same event as arriving.
    property bool animateOnLoad: false

    property int duration: 220

    default property alias content: holder.data

    readonly property Item item: holder.children.length > 0 ? holder.children[0] : null

    // The child sizes itself, so the slot is measured off it rather than the
    // other way round; holder is the fixed-size stage the child is scaled on, so
    // the scale never feeds back into the width being animated.
    readonly property real contentWidth: root.item ? root.item.width : 0
    readonly property real contentHeight: root.item ? root.item.height : 0

    // Only ever false for the one frame before `animateOnLoad` lets go, which is
    // what gives the Behaviors a value to animate away from.
    property bool open: !root.animateOnLoad
    readonly property bool expanded: root.open && root.shown

    implicitWidth: root.expanded ? root.contentWidth : 0
    implicitHeight: root.contentHeight

    // Dropped out of the Row only once the slot has finished closing, so the
    // Row's spacing leaves with it instead of holding a gap open.
    visible: root.shown || root.width > 0

    Component.onCompleted: root.open = true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: holder
        anchors.centerIn: parent
        width: root.contentWidth
        height: root.contentHeight

        opacity: root.expanded ? 1 : 0
        scale: root.expanded ? 1 : 0.5

        Behavior on opacity {
            NumberAnimation {
                duration: root.duration
                easing.type: Easing.OutQuad
            }
        }

        // OutBack overshoots a little past 1, which is the pop itself. The slot
        // is unclipped, so the overshoot spills over the neighbouring gap for a
        // few frames rather than being cut off.
        Behavior on scale {
            NumberAnimation {
                duration: root.duration + 120
                easing.type: Easing.OutBack
            }
        }
    }
}
