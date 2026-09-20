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

    // The overshoot past full size. On, because an indicator here arrives into
    // a slot of its own rather than displacing something already in it; turn it
    // off where the wrapper shares its slot with another element.
    property bool pop: true

    property int duration: 400

    default property alias content: holder.content

    readonly property Item item: holder.item

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

    // The scale and fade themselves are the same motion every slot member uses;
    // the slot is unclipped, so a pop's overshoot spills over the neighbouring
    // gap for a few frames rather than being cut off.
    CrossFade {
        id: holder
        anchors.centerIn: parent
        shown: root.expanded
        pop: root.pop
        duration: root.duration
    }
}
