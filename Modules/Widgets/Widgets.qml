import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Core

// Desktop widgets: a click-through surface pinned below every window, so the
// widgets sit on the wallpaper and never take input or screen space away from
// anything else.
LazyLoader {
    active: Config.widgets.lyricsEnabled

    PanelWindow {
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        // Nothing here is interactive, and the desktop underneath should stay
        // clickable straight through it.
        mask: Region {
            item: null
        }
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "island-widgets"

        anchors {
            left: true
            right: true
            bottom: true
        }

        implicitHeight: lyrics.implicitHeight + Config.widgets.lyricsBottomMargin

        LyricsWidget {
            id: lyrics
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Config.widgets.lyricsBottomMargin
            // Never wider than the screen, however the config is set.
            width: Math.min(implicitWidth, parent.width - Config.island.padding * 2)
        }
    }
}
