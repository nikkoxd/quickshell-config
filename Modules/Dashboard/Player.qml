import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Services

Column {
    id: root
    spacing: 15
    readonly property var player: MprisService.activePlayer
    readonly property bool playing: player && player.playbackState == MprisPlaybackState.Playing
    readonly property string trackTitle: player && player.trackTitle
    readonly property string trackAlbum: player && player.trackAlbum
    readonly property string trackArtist: player && player.trackArtist
    readonly property string trackArtUrl: player && player.trackArtUrl
    readonly property real progress: MprisService.length > 0 ? Math.max(0, Math.min(1, MprisService.position / MprisService.length)) : 0

    Item {
        id: art
        readonly property int artSize: 150
        readonly property int ringOffset: 6
        readonly property int ringWidth: 3

        width: artSize + 2 * (ringOffset + ringWidth)
        height: width
        anchors.horizontalCenter: parent.horizontalCenter

        Canvas {
            id: ring
            anchors.fill: parent
            antialiasing: true

            readonly property color trackColor: Config.colorscheme.fg
            readonly property color fillColor: Config.colorscheme.accent

            onTrackColorChanged: requestPaint()
            onFillColorChanged: requestPaint()

            // Rounded rect broken into its 8 pieces, clockwise from top center.
            // Canvas' Context2D ignores setLineDash, so the partial stroke is walked by hand.
            function segments(x, y, w, h, r) {
                const q = Math.PI / 2;
                return [
                    {
                        line: [x + w / 2, y, x + w - r, y]
                    },
                    {
                        arc: [x + w - r, y + r, -q]
                    },
                    {
                        line: [x + w, y + r, x + w, y + h - r]
                    },
                    {
                        arc: [x + w - r, y + h - r, 0]
                    },
                    {
                        line: [x + w - r, y + h, x + r, y + h]
                    },
                    {
                        arc: [x + r, y + h - r, q]
                    },
                    {
                        line: [x, y + h - r, x, y + r]
                    },
                    {
                        arc: [x + r, y + r, Math.PI]
                    },
                    {
                        line: [x + r, y, x + w / 2, y]
                    }
                ];
            }

            function segmentLength(seg, r) {
                if (seg.arc)
                    return r * Math.PI / 2;
                const dx = seg.line[2] - seg.line[0];
                const dy = seg.line[3] - seg.line[1];
                return Math.sqrt(dx * dx + dy * dy);
            }

            // Strokes the first `t` (0..1) of the outline.
            function strokeOutline(ctx, x, y, w, h, r, t) {
                const segs = ring.segments(x, y, w, h, r);
                let total = 0;
                for (let i = 0; i < segs.length; i++)
                    total += ring.segmentLength(segs[i], r);

                let remaining = total * t;
                ctx.beginPath();
                ctx.moveTo(x + w / 2, y);

                for (let i = 0; i < segs.length && remaining > 0; i++) {
                    const seg = segs[i];
                    const len = ring.segmentLength(seg, r);
                    const frac = Math.min(1, remaining / len);
                    remaining -= len;

                    if (seg.arc) {
                        const start = seg.arc[2];
                        ctx.arc(seg.arc[0], seg.arc[1], r, start, start + frac * Math.PI / 2, false);
                    } else {
                        ctx.lineTo(seg.line[0] + (seg.line[2] - seg.line[0]) * frac, seg.line[1] + (seg.line[3] - seg.line[1]) * frac);
                    }
                }

                ctx.stroke();
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const inset = art.ringWidth / 2;
                const w = width - art.ringWidth;
                const h = height - art.ringWidth;
                const r = Math.min(Config.island.radius + art.ringOffset + inset, Math.min(w, h) / 2);

                ctx.lineWidth = art.ringWidth;
                ctx.lineCap = "round";

                ctx.strokeStyle = ring.trackColor;
                ctx.globalAlpha = 0.15;
                ring.strokeOutline(ctx, inset, inset, w, h, r, 1);

                if (root.progress <= 0)
                    return;

                ctx.strokeStyle = ring.fillColor;
                ctx.globalAlpha = 1;
                ring.strokeOutline(ctx, inset, inset, w, h, r, root.progress);
            }
        }

        Connections {
            target: root
            function onProgressChanged() {
                ring.requestPaint();
            }
        }

        ClippingRectangle {
            id: imageMask
            width: art.artSize
            height: art.artSize
            radius: Config.island.radius
            anchors.centerIn: parent
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Config.colorscheme.fg
                opacity: 0.1
            }

            ThemedText {
                text: "music-note-simple"
                icon: true
                font.pixelSize: 48
                anchors.centerIn: parent
            }

            Image {
                id: image
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: root.trackArtUrl
                antialiasing: true
                asynchronous: true
            }

            Item {
                id: overlay
                anchors.fill: parent
                opacity: 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Config.colorscheme.bg
                    opacity: 0.65
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    PlayerButton {
                        text: "skip-back"
                        onClicked: root.player.previous()
                    }

                    PlayerButton {
                        text: MprisService.activePlayer.isPlaying ? "pause" : "play"
                        onClicked: root.player.togglePlaying()
                    }

                    PlayerButton {
                        text: "skip-forward"
                        onClicked: root.player.next()
                    }
                }
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) {
                        overlay.opacity = 1;
                    } else {
                        overlay.opacity = 0;
                    }
                }
            }
        }
    }

    Column {
        spacing: 5
        anchors.left: parent.left
        anchors.right: parent.right

        ScrollingText {
            text: root.trackTitle
            isHeading: true
            bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            maxWidth: 150
        }

        ScrollingText {
            text: root.trackAlbum
            opacity: 0.8
            anchors.horizontalCenter: parent.horizontalCenter
            centered: true
            maxWidth: 150
        }

        ScrollingText {
            text: root.trackArtist
            opacity: 0.8
            anchors.horizontalCenter: parent.horizontalCenter
            centered: true
            maxWidth: 150
        }
    }
}
