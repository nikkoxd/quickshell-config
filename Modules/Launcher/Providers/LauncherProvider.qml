import QtQuick

QtObject {
    property string providerId
    property string headerIcon: "search"
    property string placeholder: "Search..."
    property var svc // injected LauncherService

    // Returns an array of entries:
    // [{ name, genericName, icon, execute, preventClose }]
    function entries(query) {
        return [];
    }
}
