import QtQuick
import Quickshell.Widgets
import qs.Core
import qs.Services

ClippingRectangle {
    id: cava
    anchors.verticalCenter: parent.verticalCenter
    visible: Config.visualizer.displayVisualizer
             && Config.visualizer.mode === "background"
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
            const cap = cava.maxHeight;

            ctx.clearRect(0, 0, width, height);
            if (count < 2) return;

            var points = [];
            for (let i = 0; i < count; i++) {
                points.push({
                    x: (i / (count - 1)) * width,
                    y: height - Math.max(1, values[i] * height * cap)
                });
            }

            const c = cava.visualizerColor;
            const grad = ctx.createLinearGradient(0, 0, 0, height);
            grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, cava.topOpacity));
            grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, cava.bottomOpacity));

            ctx.beginPath();
            ctx.moveTo(0, height);
            ctx.lineTo(points[0].x, points[0].y);

            for (let i = 1; i < points.length - 2; i++) {
                const xc = (points[i].x + points[i + 1].x) / 2;
                const yc = (points[i].y + points[i + 1].y) / 2;
                ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
            }
            ctx.quadraticCurveTo(
                points[count - 2].x, points[count - 2].y,
                points[count - 1].x, points[count - 1].y
            );

            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fillStyle = grad;
            ctx.fill();
        }
    }
}
