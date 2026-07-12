pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.Core
import qs.Services

Column {
    spacing: 5

    Row {
        spacing: 10

        ThemedText {
            text: DateService.hours + ":" + DateService.minutes
            font.pixelSize: 24
            font.bold: true
        }

        ThemedText {
            text: DateService.date
            opacity: 0.8
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
        }
    }

    DayOfWeekRow {
        anchors.left: parent.left
        anchors.right: parent.right
        delegate: ThemedText {
            text: shortName
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.8
            required property string shortName
        }
    }

    MonthGrid {
        id: monthGrid
        readonly property date today: new Date()

        delegate: Item {
            id: delegateRoot
            implicitWidth: 24
            implicitHeight: 24

            required property int day
            required property int month
            required property int year

            readonly property bool isToday: {
                var t = monthGrid.today;
                return day === t.getDate() && month === t.getMonth() && year === t.getFullYear();
            }
            readonly property bool isCurrentMonth: month === monthGrid.month

            Rectangle {
                anchors.fill: parent
                color: Config.colorscheme.accent
                radius: width / 3
                visible: delegateRoot.isToday
            }

            ThemedText {
                anchors.centerIn: parent
                text: delegateRoot.day
                horizontalAlignment: Text.AlignHCenter
                color: delegateRoot.isToday ? Config.colorscheme.bg : Config.colorscheme.fg
                opacity: delegateRoot.isCurrentMonth ? 1.0 : 0.5
            }
        }
    }
}
