pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding * 2
    implicitHeight: row.implicitHeight + Config.island.padding * 2
    focused: true
    dismissable: false
    displayInFullscreen: true
    closeOnUnhover: true
    popups: tray.popups

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.viewChangeRequested("controlCenter")
    }

    function switchTab(tab) {
        root.currentTab = tab;
    }

    RowLayout {
        id: row
        spacing: 30
        x: Config.island.padding
        y: Config.island.padding

        Player {
            Layout.alignment: Qt.AlignVCenter
            visible: Mpris.players.values.length > 0
        }

        Loader {
            id: calTrayLoader
            property Component cal: Calendar {}
            property Component lyrics: Lyrics {}

            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: DashboardService.togglePanel()
            }

            sourceComponent: DashboardService.panel === 0 ? cal : lyrics
        }

        Tray {
            id: tray
            onCloseRequested: root.closeRequested()
            Layout.fillHeight: true
        }
    }
}
