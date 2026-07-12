import QtQuick

Text {
    font.family: icon ? "Material Symbols Outlined" : Config.theme.fontFamily
    font.pixelSize: isHeading ? Config.theme.fontSize * 1.15 : Config.theme.fontSize
    color: Config.colorscheme.fg

    property bool icon: false
    property bool isHeading: false
}
