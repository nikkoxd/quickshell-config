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

        return root.svc.fuzzyFilter(q, themes);
    }
}
