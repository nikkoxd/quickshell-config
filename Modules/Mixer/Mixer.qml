import Quickshell.Services.Pipewire
import QtQuick
import qs.Core

View {
    id: root
    implicitWidth: list.implicitWidth + 30
    implicitHeight: list.implicitHeight + 30
    focused: true
    dismissable: false
    displayInFullscreen: true

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.LeftButton) {
                root.viewChangeRequested("dashboard");
            } else {
                root.viewChangeRequested("controlCenter");
            }
        }
    }

    PwNodeLinkTracker {
        id: linkTracker
        node: Pipewire.defaultAudioSink
    }

    ListView {
        id: list
        implicitWidth: 310
        implicitHeight: contentHeight
        anchors.centerIn: parent
        spacing: 10
        model: linkTracker.linkGroups
        delegate: MixerEntry {
            node: modelData.source
            required property PwLinkGroup modelData
        }
    }
}
