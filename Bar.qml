pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import qs.Core
import qs.Modules.Default as DefaultModule
import qs.Modules.ControlCenter as ControlCenterModule
import qs.Modules.Dashboard as DashboardModule
import qs.Modules.Launcher as LauncherModule
import qs.Modules.LocalSend as LocalSendModule
import qs.Modules.Wallpapers as WallpapersModule
import qs.Modules.Mixer as MixerModule
import qs.Services

Item {
    id: root
    implicitWidth: content.currentView.implicitWidth
    implicitHeight: content.currentView.implicitHeight

    property string currentItem: "clock"
    property string defaultItem: "clock"
    property alias content: content
    property Component clock: DefaultModule.Clock {}
    property Component lyrics: DefaultModule.Lyrics {}
    property Component notification: DefaultModule.Notification {}
    property Component player: DefaultModule.Player {}
    property Component workspaces: DefaultModule.Workspaces {}
    property Component volume: DefaultModule.Volume {}
    property Component controlCenter: ControlCenterModule.ControlCenter {}
    property Component dashboard: DashboardModule.Dashboard {}
    property Component launcher: LauncherModule.Launcher {}
    property Component wallpaperSelector: WallpapersModule.WallpaperSelector {}
    property Component localsend: LocalSendModule.LocalSend {}
    property Component mixer: MixerModule.Mixer {}

    PropertyAnimation {
        id: blurTransitionAnimation
        target: root
        property: "transitionBlur"
        from: 1.0
        to: 0.0
        duration: 300
        easing.type: Easing.OutQuart
    }

    function openDefaultView() {
        console.log("[bar] Opening default view");
        root.currentItem = root.defaultItem;
        content.replace(root[root.defaultItem]);
    }

    function openView(view, params) {
        console.log("[bar] Opening", view, "view");
        if (view === root.currentItem)
            return;
        root.currentItem = view;
        if (params !== undefined) {
            content.replace(root[view], params);
        } else {
            content.replace(root[view]);
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(view: string) {
            if (view === root.currentItem) {
                root.openDefaultView();
            } else {
                root.openView(view);
            }
        }
    }

    Connections {
        target: content.currentItem
        enabled: content.currentItem !== null
        function onCloseRequested() {
            root.openDefaultView();
            LocalSendService.rejectTransfer();
        }
        function onViewChangeRequested(view) {
            root.openView(view);
        }
        function onDefaultViewChangeRequested(view) {
            root.defaultItem = view;
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (!content.currentView.dismissable)
                return;
            root.openView("workspaces");
        }
    }

    Connections {
        target: MprisService
        function onTrackChanged() {
            if (!content.currentView.dismissable)
                return;
            root.openView("player");
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        function onVolumeChanged() {
            if (!content.currentView.dismissable)
                return;
            root.openView("volume");
        }
    }

    Connections {
        target: NotificationService.server
        function onNotification(notification) {
            notification.tracked = true;

            if (!content.currentView.dismissable || NotificationService.muted)
                return;
            root.openView("notification", {
                notification: notification
            });
        }
    }

    Connections {
        target: LocalSendService
        function onPrepareUploadReceived(transferData) {
            console.log("[localsend] Prepare upload received");
            root.openView("localsend", {
                transferData: transferData
            });
        }
    }

    Cava {}

    StackView {
        id: content
        width: currentItem && currentItem.implicitWidth
        height: currentItem && currentItem.implicitHeight
        anchors.fill: parent
        clip: true
        initialItem: root.clock
        readonly property View currentView: content.currentItem as View

        replaceEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutQuart
            }
            PropertyAnimation {
                property: "scale"
                from: 0.8
                to: 1
                duration: 300
                easing.type: Easing.OutQuart
            }
        }

        replaceExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 0
            }
        }
    }

    DropArea {
        anchors.fill: parent

        onEntered: (drag) => {
            if (drag.hasUrls && root.currentItem !== "localsend") {
                root.openView("localsend");
            }
        }

        onDropped: (drop) => {
            if (drop.hasUrls && content.currentItem && root.currentItem === "localsend") {
                let urls = [];
                for (let i = 0; i < drop.urls.length; i++) {
                    urls.push(drop.urls[i].toString());
                }
                content.currentItem.files = urls;
            }
        }

        onExited: {
            if (root.currentItem === "localsend" && content.currentItem && content.currentItem.currentState === LocalSend.State.DragPrompt) {
                root.openDefaultView();
            }
        }
    }
}
