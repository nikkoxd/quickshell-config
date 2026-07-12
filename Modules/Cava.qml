import QtQuick
import Quickshell.Widgets
import qs.Core
import qs.Services

ClippingRectangle {
    id: cava
    anchors.verticalCenter: parent.verticalCenter
    visible: Config.visualizer.displayVisualizer
             && MprisService.activePlayer !== undefined 
             && MprisService.activePlayer.isPlaying
    color: "transparent"
    radius: Config.island.radius
    property real maxHeight: Config.visualizer.visualizerHeight
    property color visualizerColor: Config.colorscheme.accent
    property real topOpacity: Config.visualizer.topOpacity
    property real bottomOpacity: Config.visualizer.bottomOpacity

    width: parent.width
    height: parent.height

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        property var cavaValues: CavaService.values
        onCavaValuesChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            const values = cavaValues;
            const count  = values ? values.length : 0;
            const w = width;
            const h = height;
            const cap = cava.maxHeight;

            ctx.clearRect(0, 0, w, h);
            if (count < 2) return;

            var points = [];
            for (let i = 0; i < count; i++) {
                points.push({
                    x: (i / (count - 1)) * w,
                    y: h - Math.max(1, values[i] * h * cap)
                });
            }

            const c = cava.visualizerColor;
            const grad = ctx.createLinearGradient(0, 0, 0, h);
            grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, cava.topOpacity));
            grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, cava.bottomOpacity));

            // ---- filled area under the curve ----
            ctx.beginPath();
            ctx.moveTo(0, h);
            ctx.lineTo(points[0].x, points[0].y);

            // smooth quadratic curve through mid-points
            for (let i = 1; i < points.length - 2; i++) {
                const xc = (points[i].x + points[i + 1].x) / 2;
                const yc = (points[i].y + points[i + 1].y) / 2;
                ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
            }

            // connect the last two points
            ctx.quadraticCurveTo(
                points[count - 2].x, points[count - 2].y,
                points[count - 1].x, points[count - 1].y
            );

            ctx.lineTo(w, h);
            ctx.closePath();
            ctx.fillStyle = grad;
            ctx.fill();

            // ---- crisp top stroke ----
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (let i = 1; i < points.length - 2; i++) {
                const xc = (points[i].x + points[i + 1].x) / 2;
                const yc = (points[i].y + points[i + 1].y) / 2;
                ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
            }
            ctx.quadraticCurveTo(
                points[count - 2].x, points[count - 2].y,
                points[count - 1].x, points[count - 1].y
            );
            // ctx.strokeStyle = cava.visualizerColor;
            // ctx.lineWidth = 1.5;
            // ctx.stroke();
        }
    }
}
