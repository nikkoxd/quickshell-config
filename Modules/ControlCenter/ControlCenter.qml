import QtQuick
import QtQuick.Layouts
import qs.Core

View {
    id: root
    implicitWidth: row.implicitWidth + Config.island.padding
    implicitHeight: row.implicitHeight + Config.island.padding
    focused: true
    dismissable: false
    displayInFullscreen: true
    closeOnUnhover: true

    // Every column is this tall, so showing or hiding the notification column
    // only animates the island's width.
    readonly property int contentHeight: 220

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.viewChangeRequested("dashboard")
    }

    RowLayout {
        id: row
        spacing: Config.island.padding / 2
        x: Config.island.padding / 2
        y: Config.island.padding / 2

        ControlCenterSettings {
            Layout.preferredWidth: 120
            Layout.preferredHeight: root.contentHeight

            onViewChangeRequested: (view) => root.viewChangeRequested(view)
        }

        ControlCenterVolume {
            contentHeight: root.contentHeight
        }

        ControlCenterNotifications {
            contentHeight: root.contentHeight
        }
    }
}
