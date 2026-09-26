pragma ComponentBehavior: Bound

import QtQuick
import qs.Core
import qs.Services

// The calendar, as a scrollable run of days centred on today rather than a
// month grid: the island is wide and short, so a strip fits the shape and
// scrolling across a month boundary costs nothing.
//
// The model is built once from `span`, which therefore also bounds how far the
// strip scrolls. `today` is likewise resolved once — the view is recreated
// every time the dashboard opens, so it can never go stale while on screen.
Item {
    id: root

    readonly property int span: 180
    readonly property int cellWidth: 44
    readonly property date today: new Date()

    implicitHeight: header.implicitHeight + 6 + list.height

    // Centres today and then snaps the viewport to a cell boundary, so the
    // strip never ends on a half-drawn day at either edge.
    function centreOnToday() {
        scrollAnim.stop();
        list.positionViewAtIndex(root.span, ListView.Center);
        list.contentX = Math.round(list.contentX / root.cellWidth) * root.cellWidth;
    }

    // A horizontal ListView ignores a vertical wheel, which is the only one
    // most mice have, so the strip maps it onto its own axis by hand. The
    // target chains onto the running animation so ticks in quick succession
    // add up, and is snapped to a cell so the wheel lands the viewport where a
    // flick would.
    function scrollByCells(cells) {
        const max = Math.max(0, list.contentWidth - list.width);
        const from = scrollAnim.running ? scrollAnim.to : list.contentX;
        const target = Math.max(0, Math.min(max, Math.round(from / root.cellWidth + cells) * root.cellWidth));
        if (target === from)
            return;

        list.cancelFlick();
        scrollAnim.stop();
        scrollAnim.to = target;
        scrollAnim.start();
    }

    NumberAnimation {
        id: scrollAnim
        target: list
        property: "contentX"
        duration: 200
        easing.type: Easing.OutCubic
    }

    function dateAt(index) {
        const d = new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        d.setDate(d.getDate() + index - root.span);
        return d;
    }

    // Whatever sits under the middle of the viewport names the month. Reading
    // `contentX` here is what re-runs it while scrolling.
    readonly property int centreIndex: {
        const i = list.indexAt(list.contentX + list.width / 2, list.height / 2);
        return i < 0 ? root.span : i;
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: monthRow.implicitHeight

        Row {
            id: monthRow
            anchors.left: parent.left
            spacing: 6

            ThemedText {
                text: Qt.formatDate(root.dateAt(root.centreIndex), "MMMM yyyy")
                opacity: 0.8
            }

            // Scrolling away from today leaves no way back, so the month
            // doubles as the way home.
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: "arrow-u-up-left"
                icon: true
                font.pixelSize: 12
                opacity: jumpHover.hovered ? 1 : 0.5
                visible: root.centreIndex !== root.span

                HoverHandler {
                    id: jumpHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    gesturePolicy: TapHandler.WithinBounds
                    onTapped: root.centreOnToday()
                }
            }
        }

        ThemedText {
            anchors.right: parent.right
            anchors.verticalCenter: monthRow.verticalCenter
            text: DateService.hours + ":" + DateService.minutes
            opacity: 0.8
        }
    }

    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 6
        height: 58
        orientation: ListView.Horizontal
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem
        model: root.span * 2 + 1

        Component.onCompleted: root.centreOnToday()

        // Dragging by hand wins over whatever the wheel was still animating.
        onDragStarted: scrollAnim.stop()

        // A notch is a day. Deltas accumulate because a touchpad sends many
        // small ones, and dropping those would leave it unable to scroll at
        // all.
        property real wheelAccum: 0

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            acceptedModifiers: Qt.NoModifier

            onWheel: event => {
                const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                list.wheelAccum += delta;

                const cells = Math.trunc(list.wheelAccum / 120);
                if (cells === 0)
                    return;

                list.wheelAccum -= cells * 120;
                root.scrollByCells(-cells);
            }
        }

        delegate: Item {
            id: cell
            required property int index

            readonly property date date: root.dateAt(cell.index)
            readonly property bool isToday: cell.index === root.span
            readonly property bool isWeekend: cell.date.getDay() === 0 || cell.date.getDay() === 6

            width: root.cellWidth
            height: list.height

            Column {
                anchors.centerIn: parent
                spacing: 4

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(cell.date, "ddd")
                    font.pixelSize: Config.theme.fontSize * 0.8
                    opacity: cell.isWeekend ? 0.5 : 0.75
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: width / 3
                    color: cell.isToday ? Config.colorscheme.accent : "transparent"

                    ThemedText {
                        anchors.centerIn: parent
                        text: cell.date.getDate()
                        color: cell.isToday ? Config.colorscheme.bg : Config.colorscheme.fg
                        opacity: cell.isToday || !cell.isWeekend ? 1 : 0.6
                    }
                }
            }
        }
    }
}
