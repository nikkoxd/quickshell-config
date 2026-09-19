pragma ComponentBehavior: Bound

import QtQuick
import qs.Core

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
        list.positionViewAtIndex(root.span, ListView.Center);
        list.contentX = Math.round(list.contentX / root.cellWidth) * root.cellWidth;
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

    Row {
        id: header
        spacing: 6

        ThemedText {
            text: Qt.formatDate(root.dateAt(root.centreIndex), "MMMM yyyy")
            opacity: 0.8
        }

        // Scrolling away from today leaves no way back, so the month doubles as
        // the way home.
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
