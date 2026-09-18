// Qualified so `ScrollBar` below is unambiguously the Controls one.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

// A scroll container: children are stacked in a column that keeps its natural
// height, and the whole column scrolls once it outgrows the viewport. Each
// scrollbar only appears while that axis actually overflows.
Flickable {
    id: root

    // Children go into the inner column, so they still lay out with Layout.*
    // attached properties the way they would in any other ColumnLayout.
    default property alias content: column.data
    property alias spacing: column.spacing
    // Kept clear for the scrollbars. Reserved unconditionally: if it depended on
    // a bar being visible, the content size would feed back into the overflow
    // test that shows the bar.
    property real gutter: 14
    // Floor under the content width. A Flickable has no layout minimum of its
    // own, so without this it absorbs the whole squeeze in a narrow window and
    // the controls inside collapse to nothing; past this point the content
    // scrolls sideways instead.
    property real minContentWidth: 0

    readonly property bool overflowingY: root.contentHeight > root.height
    readonly property bool overflowingX: root.contentWidth > root.width

    contentWidth: column.width + root.gutter
    contentHeight: column.implicitHeight + (root.overflowingX ? root.gutter : 0)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    // Nothing to drag while everything fits, and leaving it interactive would
    // swallow drags aimed at the controls inside.
    interactive: root.overflowingY || root.overflowingX

    ColumnLayout {
        id: column
        width: Math.max(root.width - root.gutter, root.minContentWidth)
        spacing: 10
    }

    Controls.ScrollBar.vertical: Controls.ScrollBar {
        id: verticalBar
        policy: root.overflowingY ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff

        contentItem: Rectangle {
            implicitWidth: 6
            radius: width / 2
            color: Qt.alpha(Config.colorscheme.fg, verticalBar.pressed ? 0.6 : verticalBar.hovered ? 0.45 : 0.25)

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }

        background: Rectangle {
            implicitWidth: 6
            radius: width / 2
            color: Qt.alpha(Config.colorscheme.fg, 0.08)
        }
    }

    Controls.ScrollBar.horizontal: Controls.ScrollBar {
        id: horizontalBar
        policy: root.overflowingX ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff

        contentItem: Rectangle {
            implicitHeight: 6
            radius: height / 2
            color: Qt.alpha(Config.colorscheme.fg, horizontalBar.pressed ? 0.6 : horizontalBar.hovered ? 0.45 : 0.25)

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }

        background: Rectangle {
            implicitHeight: 6
            radius: height / 2
            color: Qt.alpha(Config.colorscheme.fg, 0.08)
        }
    }
}
