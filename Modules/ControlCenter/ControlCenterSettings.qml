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
        icon: "volume_up"
        active: Pipewire.defaultAudioSink.audio.muted
        activeIcon: "volume_off"
        onClicked: (button) => {
            if (button === Qt.LeftButton) {
                root.viewChangeRequested("mixer");
            } else {
                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
            }
        }
    }

    ControlCenterButton {
        icon: "notifications"
        active: NotificationService.muted
        activeIcon: "notifications_off"
        onClicked: {
            NotificationService.muted = !NotificationService.muted
        }
    }

    ControlCenterButton {
        icon: "bluetooth_disabled"
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
        icon: "camera"
        onClicked: {
            root.viewChangeRequested("recorder");
        }
    }

    ControlCenterButton {
        icon: "wallpaper"
        onClicked: {
            root.viewChangeRequested("wallpaperSelector");
        }
    }

    ControlCenterButton {
        icon: "rocket_launch"
        onClicked: {
            root.viewChangeRequested("launcher");
        }
    }
}
