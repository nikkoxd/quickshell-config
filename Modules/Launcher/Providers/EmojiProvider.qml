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
        if (!query)
            return root.allEntries.slice(0, root.maxResults);

        const q = query.toLowerCase();
        const matches = [];
        const all = root.allEntries;
        for (let i = 0; i < all.length; i++) {
            const idx = all[i].search.indexOf(q);
            if (idx !== -1)
                matches.push({ entry: all[i], idx });
        }
        // Earlier match position (name comes first in `search`) ranks higher;
        // break ties toward shorter names so exact-ish matches float up.
        matches.sort((a, b) => a.idx - b.idx || a.entry.name.length - b.entry.name.length);

        const out = [];
        for (let i = 0; i < matches.length && i < root.maxResults; i++)
            out.push(matches[i].entry);
        return out;
    }
}
