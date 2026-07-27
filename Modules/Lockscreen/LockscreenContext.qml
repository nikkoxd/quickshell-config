import Quickshell
import QtQuick

Scope {
    property var currentText: ""
    signal unlockRequested
    signal unlocked

    function tryUnlock() {
        if (currentText == "") return;
        unlockRequested();
    }
}
