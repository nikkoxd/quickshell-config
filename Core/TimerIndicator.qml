import QtQuick
import qs.Services

Item {
    id: root
    implicitWidth: 20
    implicitHeight: 20
    visible: TimerService.active
    opacity: TimerService.running ? 1 : 0.5

    readonly property real progress: TimerService.duration > 0
        ? Math.max(0, Math.min(1, TimerService.remaining / TimerService.duration))
        : 0

    property real thickness: 2

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    Canvas {
        id: ring
        anchors.fill: parent

        readonly property real progress: root.progress
        readonly property color trackColor: Config.colorscheme.dim
        readonly property color arcColor: Config.colorscheme.accent

        onProgressChanged: ring.requestPaint()
        onTrackColorChanged: ring.requestPaint()
        onArcColorChanged: ring.requestPaint()

        onPaint: {
            const ctx = ring.getContext("2d");
            ctx.reset();

            const radius = Math.min(ring.width, ring.height) / 2 - root.thickness / 2;
            const cx = ring.width / 2;
            const cy = ring.height / 2;
            const start = -Math.PI / 2;

            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";

            ctx.strokeStyle = ring.trackColor;
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, Math.PI * 2);
            ctx.stroke();

            if (ring.progress <= 0)
                return;

            ctx.strokeStyle = ring.arcColor;
            ctx.beginPath();
            ctx.arc(cx, cy, radius, start, start + Math.PI * 2 * ring.progress);
            ctx.stroke();
        }
    }

    ThemedText {
        text: "timer"
        icon: true
        font.pixelSize: 12
        anchors.centerIn: parent
    }
}
