// Qualified so `TextField` below is unambiguously the Controls one and not
// this file itself.
import QtQuick
import QtQuick.Controls as Controls

Controls.TextField {
    id: root

    // Fully rounded ends, as the lockscreen password field uses.
    property bool pill: false
    // No background at all — the field is drawn by whatever contains it.
    property bool borderless: false
    property real radius: 10
    // TextField has no horizontalPadding of its own in this Qt version.
    property real horizontalPadding: 20
    // Sizing hints handed to the background, so the control still picks up
    // whichever of the background and the content is larger.
    property real backgroundImplicitWidth: 0
    property real backgroundImplicitHeight: 40

    color: Config.colorscheme.fg
    placeholderTextColor: Qt.alpha(Config.colorscheme.fg, 0.5)
    selectionColor: Config.colorscheme.accent
    selectedTextColor: Config.colorscheme.bg
    font.family: Config.theme.fontFamily
    font.pixelSize: Config.theme.fontSize
    leftPadding: root.horizontalPadding
    rightPadding: root.horizontalPadding

    background: Rectangle {
        implicitWidth: root.backgroundImplicitWidth
        implicitHeight: root.backgroundImplicitHeight
        color: root.borderless ? "transparent" : Config.colorscheme.surface
        radius: root.pill ? height / 2 : root.radius
    }
}
