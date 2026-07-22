import QtQuick
import qs.Core
import qs.Services

LauncherProvider {
    id: root
    providerId: "passwords"
    headerIcon: "key"
    placeholder: KeePassService.locked ? unlockFailed ? "Wrong password, try again" : "Enter password" : "Search passwords..."
    hideQuery: KeePassService.locked ? true : false

    property bool unlockFailed: false
    property Connections keepassSvcConnections: Connections {
        target: KeePassService
        function onUnlockFailed() {
            root.unlockFailed = true
        }
    }

    function entries(query) {
        if (KeePassService.locked) {
            return [{
                name: "Unlock vault",
                icon: "lock_open_right",
                iconType: LauncherProvider.IconType.Material,
                preventClose: true,
                execute: function() {
                    KeePassService.unlock(query);
                    svc.clearQueryRequested();
                }
            }]
        } else if (query === "") {
            return [{
                name: "Lock vault",
                icon: "lock",
                iconType: LauncherProvider.IconType.Material,
                preventClose: true,
                execute: function() {
                    KeePassService.lock();
                }
            }]
        }

        return svc.fuzzyFilter(query, KeePassService.entries);
    }
}
