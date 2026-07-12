pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property var devices: []
    signal deviceSelected(var device)
    implicitWidth: col.width + 30
    implicitHeight: col.implicitHeight + 30

    Column {
        id: col
        spacing: 10
        width: 300
        x: 15
        y: 15

        Repeater {
            model: root.devices
            delegate: Device {
                onClicked: {
                    root.deviceSelected(modelData);
                }
            }
        }
    }
}
