import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Services

// The lyrics panel the dashboard used to carry, sized down to a few rows and
// parked on the desktop. The panel centres the active line, so a viewport three
// rows tall shows the previous line, the current one and the next.
Item {
    id: root

    // Rows of lyrics visible at once. The panel keeps the active line centred,
    // so an odd count is what reads symmetrically.
    property int rows: Config.widgets.lyricsRows
    property real fontScale: Config.widgets.lyricsFontScale
    // Room for the current line to grow into without touching its neighbours.
    readonly property int lineSpacing: 10

    // Height of one unwrapped row, plus the list's own spacing between them. A
    // line long enough to wrap still overflows, and is clipped like any other.
    readonly property real rowHeight: metrics.height + root.lineSpacing

    implicitWidth: Config.widgets.lyricsWidth
    implicitHeight: Math.max(1, root.rows) * root.rowHeight

    FontMetrics {
        id: metrics
        font.family: Config.theme.fontFamily
        font.pixelSize: Config.theme.fontSize * root.fontScale
    }

    // Lyrics are the whole widget, so it hides itself rather than sitting on
    // the desktop as a "No lyrics found" label.
    readonly property bool hasLyrics: LyricsService.state === "synced" || (LyricsService.state === "plain" && LyricsService.plain.length > 0)
    readonly property bool shown: root.hasLyrics && (!Config.widgets.lyricsOnlyWhilePlaying || MprisService.isPlaying === true)

    opacity: root.shown ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // Whatever the wallpaper is under it, the text needs an edge of its own.
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#c0000000"
        shadowVerticalOffset: 0
        shadowHorizontalOffset: 0
        shadowBlur: 0.6
        blurMax: 24
        autoPaddingEnabled: true
    }

    Lyrics {
        id: lyrics
        anchors.fill: parent
        fontScale: root.fontScale
        horizontalAlignment: Config.widgets.lyricsCentered ? Text.AlignHCenter : Text.AlignLeft
        // The window is click-through, so neither of these can ever fire; the
        // widget only ever follows playback.
        wheelEnabled: false
        seekOnClick: false
        // Sitting over a wallpaper rather than the island's flat background,
        // the off-lines need more of the foreground colour to stay readable.
        idleOpacity: 0.55
        minOpacity: 0.25
        lineSpacing: root.lineSpacing
        activeScale: Config.widgets.lyricsActiveScale
    }
}
