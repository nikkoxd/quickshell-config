import QtQuick
import qs.Services

QtObject {
    enum IconType {
        Application, // desktop icon name → Quickshell.iconPath (default)
        Material,    // Material Symbols glyph name → ThemedText { icon: true }
        Emoji        // literal emoji glyph → ThemedText (color emoji font)
    }

    property string providerId
    property string headerIcon: "search"
    property string placeholder: "Search..."
    property bool hideQuery: false
    property var svc: LauncherService // injected LauncherService

    // Returns an array of entries:
    // [{ name, genericName, icon, iconType, execute, preventClose }]
    // iconType defaults to Application when omitted.
    function entries(query) {
        return [];
    }
}
