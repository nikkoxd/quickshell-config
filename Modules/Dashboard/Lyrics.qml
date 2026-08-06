pragma ComponentBehavior: Bound

import QtQuick
import qs.Core
import qs.Services

Item {
    id: root
    // Sized to roughly match Calendar so scroll-swapping doesn't resize the island.
    implicitWidth: 230
    implicitHeight: 230

    // Uniform bump over the base font - per-line sizing reflowed the list on every change.
    property real fontScale: 1.3

    readonly property bool synced: LyricsService.state === "synced"
    readonly property bool hasPlain: LyricsService.state === "plain" && LyricsService.plain.length > 0

    // Which line is emphasised. Deliberately not ListView.currentIndex: the view moves itself
    // when that changes, which would fight scrolling by hand.
    readonly property int activeIndex: root.synced ? LyricsService.currentIndex : -1
    // Before the first timestamp there is no active line, but line 0 should still be centred.
    readonly property int followIndex: Math.max(0, root.activeIndex)

    // Auto-follow parks while the user scrolls by hand, and resumes a few seconds later.
    property bool following: true

    onFollowIndexChanged: root.follow(true)

    /// contentY that puts line `index` in the vertical centre.
    function centerYFor(index) {
        const item = list.itemAtIndex(index);
        if (item)
            return item.y + item.height / 2 - list.height / 2;

        // Delegate isn't realised (scrolled far away) - let the view work it out, then undo the jump.
        const saved = list.contentY;
        list.positionViewAtIndex(index, ListView.Center);
        const y = list.contentY;
        list.contentY = saved;
        return y;
    }

    // Lowest/highest valid contentY. The header sits before the origin, so this starts negative.
    readonly property real minY: list.originY
    readonly property real maxY: Math.max(root.minY, list.originY + list.contentHeight - list.height)

    function scrollTo(y, animated) {
        scrollAnim.stop();
        const clamped = Math.max(root.minY, Math.min(root.maxY, y));
        if (!animated) {
            list.contentY = clamped;
            return;
        }
        scrollAnim.from = list.contentY;
        scrollAnim.to = clamped;
        scrollAnim.start();
    }

    function follow(animated) {
        if (!root.synced || !root.following || list.count === 0)
            return;

        // centerYFor is only exact once the target delegate exists. Otherwise it's an estimate
        // that can be hundreds of pixels out, so jump there and let settle converge on it -
        // animating an estimate is what makes a freshly opened panel slide into place.
        const exact = !!list.itemAtIndex(root.followIndex);
        root.scrollTo(root.centerYFor(root.followIndex), animated && exact);
        if (!exact)
            settle.restart();
    }

    /// Scrolls by hand, parking auto-follow until the user stops. The active line doesn't move.
    function scrollByPixels(delta) {
        if (root.maxY <= root.minY)
            return;

        // Chain onto the running animation so ticks in quick succession add up.
        const from = scrollAnim.running ? scrollAnim.to : list.contentY;
        const target = Math.max(root.minY, Math.min(root.maxY, from - delta));
        if (target === from)
            return;

        root.following = false;
        resumeFollow.restart();
        root.scrollTo(target, true);
    }

    // Ctrl+wheel is left alone for the Dashboard, which swaps this panel for the calendar.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        acceptedModifiers: Qt.NoModifier

        onWheel: event => root.scrollByPixels(event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * 60)
    }

    NumberAnimation {
        id: scrollAnim
        target: list
        property: "contentY"
        duration: 400
        easing.type: Easing.OutCubic
    }

    Timer {
        id: resumeFollow
        interval: 4000
        onTriggered: {
            root.following = true;
            root.follow(true);
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 6
        // contentY is driven by hand (see handleWheel / follow), never by flick physics.
        interactive: false

        // Half a viewport of padding at each end, so the first and last lines can sit centred.
        header: Item {
            width: list.width
            height: root.synced ? list.height / 2 : 0
        }
        footer: Item {
            width: list.width
            height: root.synced ? list.height / 2 : 0
        }

        model: {
            if (root.synced)
                return LyricsService.lines;
            if (root.hasPlain)
                return LyricsService.plain.split("\n");
            return [];
        }

        // A new set of lines starts centred, without an animation.
        onCountChanged: {
            root.following = true;
            resumeFollow.stop();
            settle.restart();
        }

        // Delegates are only created around the current contentY and only reach their wrapped
        // heights a frame later, so one jump usually isn't enough. Keep snapping until the
        // target delegate exists and the position it asks for stops moving.
        Timer {
            id: settle
            interval: 16
            repeat: true
            property int ticks: 0

            onRunningChanged: if (running)
                ticks = 0

            onTriggered: {
                const before = list.contentY;
                root.follow(false);
                const settled = list.itemAtIndex(root.followIndex) && Math.abs(list.contentY - before) < 0.5;
                if (settled || !root.following || ++ticks > 10)
                    stop();
            }
        }

        // Unsynced lyrics can't follow timestamps, so drift them along with playback instead.
        Binding {
            target: list
            property: "contentY"
            when: root.hasPlain && root.following && MprisService.length > 0
            value: root.minY + MprisService.position / MprisService.length * (root.maxY - root.minY)
        }

        Behavior on contentY {
            enabled: root.hasPlain
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: line
            required property int index
            required property var modelData

            readonly property int distance: root.activeIndex < 0 ? 1 : Math.abs(index - root.activeIndex)
            readonly property bool current: root.synced && distance === 0

            // How much of this line is filled. Freezes at its last value when the line stops
            // being current, so the fill can fade out where it got to instead of snapping back.
            property real fillProgress: 0

            Binding on fillProgress {
                when: line.current
                value: LyricsService.currentProgress
                restoreMode: Binding.RestoreNone
            }

            width: list.width
            implicitHeight: base.implicitHeight

            ThemedText {
                id: base
                width: parent.width
                wrapMode: Text.WordWrap
                // model is either [{time, text}] or plain strings, and can lag `synced` by a frame.
                readonly property string lineText: line.modelData && line.modelData.text !== undefined ? line.modelData.text : line.modelData || ""
                // LRC marks instrumental breaks with empty lines.
                text: root.synced && lineText.length === 0 ? "♪" : lineText
                font.pixelSize: Config.theme.fontSize * root.fontScale
                // The current line sits dim too - the fill overlay is what brightens it.
                // Everything else fades off gradually the further it is from the current line.
                opacity: !root.synced ? 0.8 : Math.max(0.12, 0.4 - line.distance * 0.07)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }

                // Geometry of each wrapped row, so the fill can run through them in reading order
                // instead of sweeping every row at once. Only recomputed on relayout.
                property var rows: []
                property var rowBuffer: []
                readonly property real totalWidth: {
                    let total = 0;
                    for (let i = 0; i < rows.length; i++)
                        total += rows[i].w;
                    return total || 1;
                }

                function publishRows() {
                    base.rows = base.rowBuffer.slice();
                }

                onLineLaidOut: row => {
                    if (row.number === 0)
                        base.rowBuffer = [];
                    base.rowBuffer.push({
                        y: row.y,
                        h: row.height,
                        w: row.implicitWidth
                    });
                    // Publishing inline would build the fill delegates mid-layout and corrupt it.
                    Qt.callLater(base.publishRows);
                }
            }

            // Karaoke fill: a fully opaque copy of the text per wrapped row, revealed left to right
            // by a clipping mask. Only mask widths change, so the text is never re-laid out.
            Item {
                id: fill
                anchors.fill: parent
                // Lights up quickly, but lingers on its way out as the next line takes over.
                opacity: line.current ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: line.current ? 120 : 600
                        easing.type: Easing.OutQuad
                    }
                }

                Repeater {
                    model: fill.visible ? base.rows : []

                    Item {
                        id: fillRow
                        required property int index
                        required property var modelData

                        // Width of every row before this one, i.e. where this row starts in the line.
                        readonly property real offset: {
                            let total = 0;
                            for (let i = 0; i < index; i++)
                                total += base.rows[i].w;
                            return total;
                        }

                        y: modelData.y
                        height: modelData.h
                        clip: true
                        width: Math.max(0, Math.min(modelData.w, base.totalWidth * line.fillProgress - offset))

                        // MprisService.position ticks at 5Hz - smooth the steps into a continuous sweep.
                        Behavior on width {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.Linear
                            }
                        }

                        ThemedText {
                            y: -fillRow.y
                            width: base.width
                            wrapMode: base.wrapMode
                            text: base.text
                            font: base.font
                        }
                    }
                }
            }

            // A MouseArea takes the grab, so the Dashboard's TapHandler won't also close the view.
            MouseArea {
                anchors.fill: parent
                enabled: root.synced
                cursorShape: Qt.PointingHandCursor
                onClicked: LyricsService.seek(line.index)
            }
        }
    }

    ThemedText {
        anchors.centerIn: parent
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        opacity: 0.8
        visible: text.length > 0
        text: LyricsService.statusText
    }
}
