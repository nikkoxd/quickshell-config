import QtQuick
import qs.Services

LauncherProvider {
    id: root
    providerId: "clipboard"
    headerIcon: "clipboard"
    placeholder: "Search clipboard..."

    Component.onCompleted: {
        CliphistService.fetch();
    }

    // CliphistService lives in qs.Services, which the providers import — so it can't
    // name the IconType enum itself without a module cycle. It flags image entries
    // instead and the mapping happens here.
    function decorate(entries) {
        return entries.map(entry => entry.isImage
            ? Object.assign({}, entry, { iconType: LauncherProvider.IconType.Preview })
            : entry);
    }

    function entries(query) {
        if (CliphistService.entries.length === 0) {
            return [{
                name: "Clipboard history is empty",
                icon: "empty",
                iconType: LauncherProvider.IconType.Material
            }]
        }
        return root.decorate(svc.substringFilter(query, CliphistService.entries, 50));
    }
}
