import QtQuick
import qs.Core
import qs.Services

// The compact half of the visualizer: a few discrete bars meant to sit inline
// next to text, as opposed to Cava.qml which paints a curve across the whole
// island. Which one is shown is decided by Config.visualizer.mode.
Row {
    id: root

    property int count: Config.visualizer.barCount
    property real barWidth: Config.visualizer.barWidth
    property real maxHeight: Config.visualizer.barMaxHeight
    property real minHeight: root.barWidth
    property color barColor: Config.colorscheme.accent

    spacing: 1
    height: root.maxHeight
    visible: Config.visualizer.displayVisualizer
             && Config.visualizer.mode === "bars"
             && MprisService.isPlaying

    // CavaService emits more bars than fit inline, so each output bar averages
    // the slice of the raw values it covers.
    readonly property var levels: {
        const values = CavaService.values;
        const n = root.count;
        if (!values || values.length === 0 || n <= 0)
            return [];

        const out = [];
        for (let i = 0; i < n; i++) {
            const start = Math.floor(i * values.length / n);
            const end = Math.max(start + 1, Math.floor((i + 1) * values.length / n));
            let sum = 0;
            for (let j = start; j < end; j++)
                sum += values[j];
            out.push(sum / (end - start));
        }
        return out;
    }

    Repeater {
        model: root.count

        Rectangle {
            required property int index
            width: root.barWidth
            height: Math.max(root.minHeight, Math.min(1, root.levels[index] ?? 0) * root.maxHeight)
            radius: width / 2
            color: root.barColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
