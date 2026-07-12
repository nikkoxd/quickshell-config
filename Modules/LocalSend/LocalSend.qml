pragma ComponentBehavior: Bound
import QtQuick
import qs.Core
import qs.Services

View {
    id: root
    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight
    focused: true
    dismissable: false
    displayInFullscreen: true

    property var files: []
    property var selectedDevice: null
    property var currentState: LocalSend.State.DragPrompt
    property var transferData: null

    enum State {
        ReceivePrompt,
        Receiving,
        ReceiveCancelled,
        ReceiveError,
        ReceiveComplete,
        DragPrompt,
        Discovery,
        DiscoveryError,
        DeviceSelect,
        Sending,
        Complete,
        Error
    }

    onFilesChanged: {
        console.log("Files changed", files);
        if (files.length > 0) {
            root.discoverDevices();
        }
    }

    onTransferDataChanged: {
        console.log("Transfer data changed", transferData);
        if (transferData) {
            root.currentState = LocalSend.State.ReceivePrompt;
        }
    }

    function discoverDevices() {
        console.log("Discovering devices");
        root.currentState = LocalSend.State.Discovery;
        LocalSendService.startDiscovery();
    }

    onSelectedDeviceChanged: {
        console.log("Selected device:", JSON.stringify(selectedDevice, null, 2));
        root.currentState = LocalSend.State.Sending;
        LocalSendService.send(root.files, root.selectedDevice);
    }

    Connections {
        target: LocalSendService

        function onDiscoveryFinished(count) {
            console.log("Discovery finished:", count);
            root.currentState = count > 0 ? LocalSend.State.DeviceSelect : LocalSend.State.DiscoveryError;
        }

        function onSendFinished(success) {
            console.log("Send finished:", success);
            root.currentState = success ? LocalSend.State.Complete : LocalSend.State.Error;
            backTimer.start();
        }

        function onTransferCancelled() {
            console.log("Transfer cancelled");
            if (root.currentState === LocalSend.State.ReceivePrompt || root.currentState === LocalSend.State.Receiving) {
                root.currentState = LocalSend.State.ReceiveCancelled;
            }
            backTimer.start();
        }

        function onTransferDone() {
            console.log("Transfer done");
            if (root.currentState === LocalSend.State.Receiving) {
                root.currentState = LocalSend.State.ReceiveComplete;
            }
            backTimer.start();
        }
    }

    Timer {
        id: backTimer
        interval: 2500
        onTriggered: root.closeRequested()
    }

    function deviceTypeToIcon(type) {
        // mobile | desktop | web | headless | server, nullable
        switch (type) {
        case "mobile":
            return "mobile";
        case "desktop":
            return "desktop_windows";
        case "web":
            return "web";
        case "headless":
            return "terminal";
        case "server":
            return "database";
        default:
            return "help";
        }
    }

    Item {
        id: container
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height

        StateLoader {
            sourceComponent: StateDisplay {
                icon: root.deviceTypeToIcon(root.transferData.deviceType)
                text: root.transferData.alias
                subText: "Wants to send you " + root.transferData.files.length + " file(s)"
                leftButtonText: "Deny"
                rightButtonText: "Accept"
                onLeftButtonClicked: {
                    root.currentState = LocalSend.State.ReceiveCancelled;
                    LocalSendService.rejectTransfer();
                }
                onRightButtonClicked: {
                    root.currentState = LocalSend.State.Receiving;
                    LocalSendService.acceptTransfer();
                }
            }
            active: root.currentState === LocalSend.State.ReceivePrompt
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "sync"
                text: "Downloading " + root.transferData.files.length + " file(s) from " + root.transferData.alias
                animated: true
            }
            active: root.currentState === LocalSend.State.Receiving
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "check"
                text: "Download complete"
            }
            active: root.currentState === LocalSend.State.ReceiveComplete
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "error"
                text: "Transfer cancelled"
            }
            active: root.currentState === LocalSend.State.ReceiveCancelled
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "attach_file"
                text: "Send elsewhere"
                subText: "Drop your stuff here"
            }
            active: root.currentState === LocalSend.State.DragPrompt
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "explore"
                text: "Discovering devices"
                animated: true
            }
            active: root.currentState === LocalSend.State.Discovery
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "error"
                text: "Nothing found!"
                subText: "Click to retry"
                onComponentClicked: root.discoverDevices()
            }
            active: root.currentState === LocalSend.State.DiscoveryError
        }

        StateLoader {
            sourceComponent: DeviceSelect {
                devices: LocalSendService.devices
                onDeviceSelected: device => {
                    root.selectedDevice = device;
                }
            }
            active: root.currentState === LocalSend.State.DeviceSelect
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "sync"
                text: "Sending files to " + root.selectedDevice.alias
                animated: true
            }
            active: root.currentState === LocalSend.State.Sending
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "error"
                text: "Failed to send files"
            }
            active: root.currentState === LocalSend.State.Error
        }

        StateLoader {
            sourceComponent: StateDisplay {
                icon: "check"
                text: "Files sent!"
            }
            active: root.currentState === LocalSend.State.Complete
        }
    }

    component StateLoader: Loader {
        visible: active
        width: visible ? implicitWidth : 0
        height: visible ? implicitHeight : 0
        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.8
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuart
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuart
            }
        }
    }
}
