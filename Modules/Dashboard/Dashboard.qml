pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Core

View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding * 2
    implicitHeight: row.implicitHeight + Config.island.padding * 2
    focused: true
    dismissable: false
    displayInFullscreen: true
    popups: tray.popups

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.LeftButton) {
                root.closeRequested();
            } else {
                root.viewChangeRequested("controlCenter");
            }
        }
    }

    function switchTab(tab) {
        root.currentTab = tab;
    }

    RowLayout {
        id: row
        spacing: 30
        anchors.centerIn: parent

        Player {
            Layout.alignment: Qt.AlignVCenter
            visible: Mpris.players.values.length > 0
        }
        Calendar {}
        Tray {
            id: tray
            onCloseRequested: root.closeRequested()
            Layout.fillHeight: true
        }
    }
}
