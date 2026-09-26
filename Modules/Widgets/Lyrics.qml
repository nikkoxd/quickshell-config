pragma ComponentBehavior: Bound

import QtQuick
import qs.Core
import qs.Services

Item {
    id: root
    // A default the island panel was sized around; the desktop widget gives it
    // a size of its own instead.
    implicitWidth: 230
    implicitHeight: 230

    // Uniform bump over the base font - per-line sizing reflowed the list on every change.
    property real fontScale: 1.3
    // Left in the panel, centred as a desktop widget. The karaoke fill follows
    // it, because each wrapped row is placed at the x the layout gave it.
    property int horizontalAlignment: Text.AlignLeft
    // Auto-follow re-centres the active line; turning it off leaves scrolling
    // entirely to the wheel.
    property bool wheelEnabled: true
    // Click-to-seek. A click-through widget window can't take the press anyway.
    property bool seekOnClick: true
    // How dim the lines around the current one sit. Over a wallpaper they need
    // to be brighter than they do inside the island.
    property real idleOpacity: 0.4
    property real minOpacity: 0.12
    // Gap between lines, which a caller sizing itself in whole rows needs too.
    property int lineSpacing: 6
    // Colour of the lyrics. Over the island's own background the foreground
    // colour is right, but a caller drawing over a wallpaper may need the
    // other end of the scheme.
    property color textColor: Config.colorscheme.fg
    // How much bigger the current line sits. This is a transform, not a font size:
    // resizing the text would re-wrap and reflow the list under the scroll position.
    property real activeScale: 1

    // LRC marks instrumental breaks with empty lines. This stands in for one.
    readonly property string placeholderText: "♪♪♪"

    readonly property bool synced: LyricsService.state === "synced"
    readonly property bool hasPlain: LyricsService.state === "plain" && LyricsService.plain.length > 0

    // Which line is emphasised. Deliberately not ListView.currentIndex: the view moves itself
    // when that changes, which would fight scrolling by hand.
    readonly property int activeIndex: root.synced ? LyricsService.currentIndex : -1
    // Before the first timestamp there is no active line, but line 0 should still be centred.
    readonly property int followIndex: Math.max(0, root.activeIndex)

    // Auto-follow parks while the user scrolls by hand, and resumes a few seconds later.
    property bool following: true

    // The fill moves with the music rather than with the 5Hz position ticks.
    PlaybackClock {
        id: clock
        active: root.visible && root.synced
    }

    // The stretch of the current line being filled right now, as character offsets
    // into its text plus how far through that stretch playback is. With word timings
    // the stretch is the word being sung, so the fill steps word by word; without
    // them it is the whole line. `from`/`to` only change at a word boundary, so the
    // widths measured off them are measured then and not every frame.
    readonly property var sweep: LyricsService.sweepAt(clock.position)
    readonly property int sweepFrom: root.sweep.from
    readonly property int sweepTo: root.sweep.to
    readonly property real sweepProgress: root.sweep.progress

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

    // Ctrl+wheel is left alone for whatever hosts the panel to use.
    WheelHandler {
        enabled: root.wheelEnabled
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
        spacing: root.lineSpacing
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

            // How much of this line is filled, in pixels along it as if its wrapped rows
            // were laid end to end. Freezes at its last value when the line stops being
            // current, so the fill can fade out where it got to instead of snapping back.
            property real fillWidth: 0

            Binding on fillWidth {
                when: line.current
                value: base.sweepWidth
                restoreMode: Binding.RestoreNone
            }

            width: list.width
            implicitHeight: base.implicitHeight

            // Grows in place, so the rows around it keep the positions the list
            // laid out and the active line stays centred.
            scale: line.current ? root.activeScale : 1
            transformOrigin: root.horizontalAlignment === Text.AlignHCenter ? Item.Center : Item.Left

            Behavior on scale {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            ThemedText {
                id: base
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: root.horizontalAlignment
                // model is either [{time, text}] or plain strings, and can lag `synced` by a frame.
                readonly property string lineText: line.modelData && line.modelData.text !== undefined ? line.modelData.text : line.modelData || ""
                // An instrumental line has no text of its own, so three notes stand
                // in for it - the same placeholder the default view uses.
                readonly property bool placeholder: root.synced && base.lineText.length === 0
                text: base.placeholder ? root.placeholderText : base.lineText
                font.pixelSize: Config.theme.fontSize * root.fontScale
                color: root.textColor
                // The current line sits dim too - the fill overlay is what brightens it.
                // Everything else fades off gradually the further it is from the current line.
                opacity: !root.synced ? 0.8 : Math.max(root.minOpacity, root.idleOpacity - line.distance * (root.idleOpacity / 6))

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }

                FontMetrics {
                    id: metrics
                    font: base.font
                }

                // Where the swept stretch starts and ends along the line, unwrapped.
                // Only a line with a fill on screen measures: the stretch means
                // nothing on any other, and this is the one binding a word boundary
                // re-runs. The gate is the fill rather than `line.current` because
                // `current` going false is also what freezes `fillWidth`, and spans
                // that collapsed to zero in that same pass would be what the freeze
                // caught - the outgoing fill snapping shut instead of fading out
                // where the line finished. The fill outlives `current` by its fade.
                //
                // An empty line has no characters for the sweep to land on, so the
                // placeholder standing in for it fills as a whole, on the line
                // progress the sweep already reports for a line without words.
                readonly property real spanStart: fill.visible && !base.placeholder ? metrics.advanceWidth(base.text.substring(0, root.sweepFrom)) : 0
                readonly property real spanEnd: !fill.visible ? 0 : base.placeholder ? base.metricWidth : metrics.advanceWidth(base.text.substring(0, root.sweepTo))
                readonly property real metricWidth: metrics.advanceWidth(base.text) || 1
                // Those widths are the font's; the rows' are what was actually laid out,
                // a wrap having dropped the space it broke on. So the reach crosses over
                // as a fraction of the line rather than as pixels.
                readonly property real sweepWidth: base.totalWidth * Math.max(0, Math.min(1, (base.spanStart + (base.spanEnd - base.spanStart) * root.sweepProgress) / base.metricWidth))

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

                        // Where this row starts once the Text has aligned it.
                        // `TextLine.x` is 0 whatever the alignment, so the
                        // offset the paint applies has to be redone here or the
                        // fill clips an empty strip left of the glyphs.
                        readonly property real rowX: root.horizontalAlignment === Text.AlignHCenter ? (base.width - modelData.w) / 2 : root.horizontalAlignment === Text.AlignRight ? base.width - modelData.w : 0

                        x: fillRow.rowX
                        y: modelData.y
                        height: modelData.h
                        clip: true
                        width: Math.max(0, Math.min(modelData.w, line.fillWidth - offset))

                        ThemedText {
                            x: -fillRow.rowX
                            y: -fillRow.y
                            width: base.width
                            wrapMode: base.wrapMode
                            horizontalAlignment: base.horizontalAlignment
                            text: base.text
                            font: base.font
                            color: root.textColor
                        }
                    }
                }
            }

            // A MouseArea takes the grab, so the Dashboard's TapHandler won't also close the view.
            MouseArea {
                anchors.fill: parent
                enabled: root.synced && root.seekOnClick
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
        color: root.textColor
        text: LyricsService.statusText
    }
}
