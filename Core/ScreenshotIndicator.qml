import QtQuick
import qs.Services

// Confirmation that a screenshot landed, shown in the default views for a few
// seconds instead of a notification: the crop glyph with a check badge over its
// bottom-right corner. `RecordingService` owns the timing; this only draws the
// glyph.
Item {
    id: root
    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    // The owner wraps this in a PopIn and drives it from here, which is also
    // what keeps the island from reserving the width between captures.
    readonly property bool active: RecordingService.screenshotFlash

    ThemedText {
        id: glyph
        text: "crop"
        icon: true
        font.pixelSize: 13
    }

    // The badge carries its own background disc so the check stays readable
    // where it overlaps the crop marks, and hangs off the corner rather than
    // sitting inside it — the glyph is only 13px and has no room to spare.
    Rectangle {
        anchors.horizontalCenter: glyph.right
        anchors.verticalCenter: glyph.bottom
        width: 9
        height: 9
        radius: width / 2
        color: Config.colorscheme.bg

        ThemedText {
            text: "check"
            icon: true
            font.pixelSize: 7
            color: Config.colorscheme.accent
            anchors.centerIn: parent
        }
    }
}
