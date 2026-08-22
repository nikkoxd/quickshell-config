import Quickshell.Bluetooth
import QtQml
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

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool discovering: adapter !== null && adapter.discovering

    // Bumped whenever a device's paired state flips, so the filters below re-run:
    // ObjectModel.values only notifies on insert/remove, not on property changes.
    property int revision: 0
    readonly property var pairedDevices: {
        root.revision;
        return Bluetooth.devices.values.filter(d => d.paired || d.bonded);
    }
    readonly property var pairableDevices: {
        root.revision;
        return Bluetooth.devices.values.filter(d => !d.paired && !d.bonded);
    }

    Instantiator {
        model: Bluetooth.devices
        delegate: QtObject {
            required property BluetoothDevice modelData
            readonly property bool paired: modelData.paired || modelData.bonded
            onPairedChanged: root.revision++
        }
    }

    ColumnLayout {
        id: layout
        width: 310
        anchors.centerIn: parent
        spacing: 10

        ThemedText {
            Layout.fillWidth: true
            opacity: 0.5
            visible: root.pairedDevices.length === 0
            text: "No paired devices"
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: 10
            model: root.pairedDevices
            delegate: BluetoothEntry {
                required property BluetoothDevice modelData
                width: ListView.view.width
                device: modelData
            }
        }
    }
}
