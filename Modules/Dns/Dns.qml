pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: layout.width + 30
    implicitHeight: layout.implicitHeight + 30
    focused: true
    dismissable: false
    displayInFullscreen: true

    ColumnLayout {
        id: layout
        width: 340
        anchors.centerIn: parent
        spacing: 10

        ViewHeader {
            Layout.fillWidth: true
            text: "DNS"

            IconButton {
                icon: "arrows-clockwise"
                onClicked: DnsService.refresh()
            }
        }

        ThemedText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            opacity: 0.5
            text: {
                if (DnsService.error !== "")
                    return DnsService.error;
                if (DnsService.busy)
                    return "Applying…";
                if (DnsService.connectionName === "")
                    return "No active connection";
                return DnsService.connectionName;
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: 10
            model: DnsService.entries

            delegate: DnsEntry {
                required property var modelData

                width: ListView.view.width
                entry: modelData
                current: modelData.name === DnsService.currentName
                busy: DnsService.busy
                onActivated: DnsService.apply(modelData)
            }
        }
    }
}
