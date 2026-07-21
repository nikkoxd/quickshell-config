import QtQuick

QtObject {
    enum IconType {
        Application, // desktop icon name → Quickshell.iconPath (default)
        Material     // Material Symbols glyph name → ThemedText { icon: true }
    }

    property string providerId
    property string headerIcon: "search"
    property string placeholder: "Search..."
    property var svc // injected LauncherService

    // Returns an array of entries:
    // [{ name, genericName, icon, iconType, execute, preventClose }]
    // iconType defaults to Application when omitted.
    function entries(query) {
        return [];
    }
}
