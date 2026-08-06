import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

GridLayout {
    id: root
    width: parent.width
    rowSpacing: 10
    columnSpacing: 10
    columns: 3

    signal viewChangeRequested(view: string)

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    ControlCenterButton {
        icon: "speaker-high"
        active: Pipewire.defaultAudioSink.audio.muted
        activeIcon: "speaker-slash"
        onClicked: (button) => {
            if (button === Qt.LeftButton) {
                root.viewChangeRequested("mixer");
            } else {
                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
            }
        }
    }

    ControlCenterButton {
        icon: "bell"
        active: NotificationService.muted
        activeIcon: "bell-slash"
        onClicked: {
            NotificationService.muted = !NotificationService.muted
        }
    }

    ControlCenterButton {
        icon: "bluetooth-slash"
        active: Bluetooth.defaultAdapter.enabled
        activeIcon: "bluetooth"
        onClicked: (button) => {
            if (button === Qt.LeftButton) {
                root.viewChangeRequested("bluetooth");
            } else {
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
        }
    }

    ControlCenterButton {
        icon: "aperture"
        onClicked: {
            root.viewChangeRequested("recorder");
        }
    }

    ControlCenterButton {
        icon: "image"
        onClicked: {
            root.viewChangeRequested("wallpaperSelector");
        }
    }

    ControlCenterButton {
        icon: "rocket-launch"
        onClicked: {
            root.viewChangeRequested("launcher");
        }
    }
}
