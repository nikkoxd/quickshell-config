pragma Singleton
import Quickshell
import QtQuick
import Qt.labs.folderlistmodel

Singleton {
    id: root

    // Generators write Themes/<name>.json themselves, so they are offered even
    // before that file exists.
    readonly property var generators: ["Iris", "Matugen"]

    property var names: root.generators

    function _rebuild() {
        const list = [];

        for (let i = 0; i < themeFiles.count; i++) {
            const name = String(themeFiles.get(i, "fileBaseName"));
            if (name) {
                list.push(name);
            }
        }

        for (const generator of root.generators) {
            if (!list.includes(generator)) {
                list.push(generator);
            }
        }

        list.sort();
        root.names = list;
    }

    FolderListModel {
        id: themeFiles
        folder: Qt.resolvedUrl("../Themes")
        nameFilters: ["*.json"]
        showDirs: false
        showDotAndDotDot: false
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                root._rebuild();
            }
        }
        onCountChanged: root._rebuild()
    }
}
