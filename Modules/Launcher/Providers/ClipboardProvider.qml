import QtQuick
import qs.Services

LauncherProvider {
    id: root
    providerId: "clipboard"
    headerIcon: "content_paste"
    placeholder: "Search clipboard..."

    Component.onCompleted: {
        CliphistService.fetch();
    }

    function entries(query) {
        if (CliphistService.entries.length === 0) {
            return [{
                name: "Clipboard history is empty",
                icon: "sentiment_dissatisfied",
                iconType: LauncherProvider.IconType.Material
            }]
        }
        return svc.substringFilter(query, CliphistService.entries, 50);
    }
}
