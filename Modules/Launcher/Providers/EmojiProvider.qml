import QtQuick
import Quickshell
import Quickshell.Io

LauncherProvider {
    id: root
    providerId: "emoji"
    headerIcon: "mood"
    placeholder: "Search emoji..."

    property var allEntries: []
    readonly property int maxResults: 50

    property FileView emojiFile: FileView {
        path: Qt.resolvedUrl("emoji.json")
        onLoaded: {
            const data = JSON.parse(emojiFile.text());
            root.allEntries = data.map(emoji => ({
                name: emoji.name,
                genericName: emoji.group,
                search: (emoji.name + " " + (emoji.shortcode ?? "") + " " + (emoji.keywords ?? []).join(" ")).toLowerCase(),
                icon: emoji.emoji,
                iconType: LauncherProvider.IconType.Emoji,
                execute: function() {
                    Quickshell.execDetached(["wl-copy", emoji.emoji]);
                }
            }));
        }
    }

    function entries(query) {
        return root.svc.substringFilter(query, root.allEntries, root.maxResults);
    }
}
