import QtQuick
import Qt.labs.folderlistmodel
import qs.Core

LauncherProvider {
    id: root
    providerId: "themes"
    headerIcon: "palette"
    placeholder: "Search themes..."

    property FolderListModel themesModel: FolderListModel {
        folder: Qt.resolvedUrl("../../../Themes")
        nameFilters: ["*.json"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    function entries(query) {
        const q = query;

        const themes = [];
        for (let i = 0; i < root.themesModel.count; i++) {
            const theme = root.themesModel.get(i, "fileBaseName");
            themes.push({
                name: theme,
                genericName: "Theme",
                icon: "color_lens",
                execute: function() {
                    Config.theme.colorscheme = theme;
                    root.svc.closeRequested();
                }
            });
        }

        if (!q) return themes;

        return themes.map(t => {
            return { entry: t, score: root.svc.fuzzyScore(q, t.name) };
        }).filter(item => item.score > 0)
            .sort((a, b) => b.score - a.score)
            .map(item => item.entry);
    }
}
