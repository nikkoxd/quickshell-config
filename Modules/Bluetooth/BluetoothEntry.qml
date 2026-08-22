import Quickshell.Bluetooth
import QtQuick
import qs.Core

Rectangle {
    id: root

    required property BluetoothDevice device
    // when true, tapping pairs/cancels pairing instead of connecting/disconnecting
    property bool pairMode: false

    height: 60
    radius: Config.island.radius
    color: hover.hovered ? Config.colorscheme.accent : Config.colorscheme.surface

    readonly property string statusText: {
        if (root.device.pairing)
            return "Pairing";
        if (root.pairMode)
            return "Tap to pair";

        switch (root.device.state) {
        case BluetoothDeviceState.Disconnected:
            return "Disconnected";
        case BluetoothDeviceState.Connected:
            return "Connected";
        case BluetoothDeviceState.Connecting:
            return "Connecting";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting";
        default:
            return "Unknown";
        }
    }

    // BlueZ will not auto-reconnect an untrusted device, so trust it once it
    // is paired -- otherwise headsets have to be re-connected by hand.
    Connections {
        target: root.device
        function onPairedChanged() {
            if (root.device.paired && !root.device.trusted) {
                root.device.trusted = true;
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            if (root.pairMode) {
                if (root.device.pairing) {
                    root.device.cancelPair();
                    return;
                }
                root.device.pair();
                return;
            }

            if (root.device.connected) {
                root.device.disconnect();
                return;
            }
            root.device.connect();
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        ThemedText {
            width: parent.width
            elide: Text.ElideRight
            text: root.device.name
        }

        ThemedText {
            width: parent.width
            elide: Text.ElideRight
            opacity: root.device.connected ? 1.0 : 0.5
            text: root.statusText
        }
    }
}
