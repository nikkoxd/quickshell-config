pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import qs.Core
import qs.Modules.Default as DefaultModule
import qs.Modules.Notifications as NotificationsModule
import qs.Modules.Dashboard as DashboardModule
import qs.Modules.Launcher as LauncherModule
import qs.Modules.LocalSend as LocalSendModule
import qs.Modules.Wallpapers as WallpapersModule
import qs.Modules.Bluetooth as BluetoothModule
import qs.Modules.Mixer as MixerModule
import qs.Modules.Dns as DnsModule
import qs.Modules.Settings as SettingsModule
import qs.Services

Item {
    id: root
    implicitWidth: content.currentView.implicitWidth
    implicitHeight: content.currentView.implicitHeight

    property string currentItem: "clock"
    // The dashboard's middle panel and the island's default view are one
    // choice, made in DashboardService.
    readonly property string defaultItem: DashboardService.panel === 1 ? "lyrics" : "clock"

    onDefaultItemChanged: {
        // This binding is first evaluated while the StackView is still empty,
        // and replace() there pushes a stray item that initialItem then stacks
        // on top of - visible under every later view, since they are all
        // transparent.
        if (content.depth === 0)
            return;
        // Swap under the user only while the island is already showing the
        // other default; anything else (an OSD, an open menu) is left alone.
        if (root.currentItem === "clock" || root.currentItem === "lyrics")
            root.openDefaultView();
    }
    property alias content: content

    property Component clock: DefaultModule.Clock {}
    property Component lyrics: DefaultModule.Lyrics {}
    property Component notification: DefaultModule.Notification {}
    property Component player: DefaultModule.Player {}
    property Component workspaces: DefaultModule.Workspaces {}
    property Component volume: DefaultModule.Volume {}
    property Component recorder: DefaultModule.Recorder {}
    property Component notifications: NotificationsModule.Notifications {}
    property Component dashboard: DashboardModule.Dashboard {}
    property Component launcher: LauncherModule.Launcher {}
    property Component wallpaperSelector: WallpapersModule.WallpaperSelector {}
    property Component localsend: LocalSendModule.LocalSend {}
    property Component bluetooth: BluetoothModule.Bluetooth {}
    property Component mixer: MixerModule.Mixer {}
    property Component dns: DnsModule.Dns {}

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
        hoverOpenTimer.stop();
        // Closing a view while still pointing at the island would immediately
        // re-arm the open timer. Stay closed until the pointer leaves.
        root.hoverSuppressed = islandHover.hovered;
        root.currentItem = root.defaultItem;
        content.replace(root[root.defaultItem]);
    }

    function openView(view, params) {
        console.log("[bar] Opening", view, "view");
        if (view === root.currentItem)
            return;
        hoverOpenTimer.stop();
        root.currentItem = view;
        if (params !== undefined) {
            content.replace(root[view], params);
        } else {
            content.replace(root[view]);
        }
    }

    // Hover-to-open. Pointing at a compact view swaps in `hoverItem`, and
    // leaving the island swaps out any view marked `closeOnUnhover`. Views
    // without that flag are closed by Escape, a focus grab, or their own UI.
    readonly property string hoverItem: "dashboard"
    readonly property bool hoverClosable: content.currentView?.closeOnUnhover ?? false
    property bool hoverSuppressed: false

    HoverHandler {
        id: islandHover

        onHoveredChanged: {
            if (hovered) {
                hoverCloseTimer.stop();
                if (content.currentView.dismissable && !root.hoverSuppressed)
                    hoverOpenTimer.restart();
            } else {
                hoverOpenTimer.stop();
                root.hoverSuppressed = false;
                if (root.hoverClosable)
                    hoverCloseTimer.restart();
            }
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: Config.island.hoverOpenDelay
        onTriggered: root.openView(root.hoverItem)
    }

    Timer {
        id: hoverCloseTimer
        interval: Config.island.hoverCloseDelay
        onTriggered: {
            // A popup (tray menu, dropdown) is its own window, so the island
            // reads as unhovered while the pointer is inside one. Wait it out.
            if (content.currentView.popups.length > 0) {
                hoverCloseTimer.restart();
                return;
            }
            root.openDefaultView();
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

    function screenshotKind(name) {
        switch (name) {
        case "region":
            return RecordingService.Kind.Region;
        case "window":
            return RecordingService.Kind.Window;
        case "fullscreen":
        case "screen":
            return RecordingService.Kind.Fullscreen;
        default:
            return -1;
        }
    }

    IpcHandler {
        target: "recorder"

        function screenshot(kind: string): string {
            const resolved = root.screenshotKind(kind === "" ? "region" : kind);
            if (resolved === -1) {
                return "unknown kind: " + kind + " (region, window, fullscreen)";
            }
            RecordingService.screenshot(resolved);
            return "ok";
        }

        function toggleRecording(): string {
            RecordingService.toggleRecording();
            return RecordingService.recording ? "recording" : "stopped";
        }

        function startRecording(): string {
            RecordingService.setRecording(true);
            return "recording";
        }

        function stopRecording(): string {
            RecordingService.setRecording(false);
            return "stopped";
        }

        function toggleReplay(): string {
            RecordingService.toggleReplay();
            return RecordingService.replayRunning ? "running" : "stopped";
        }

        function startReplay(): string {
            RecordingService.setReplay(true);
            return "running";
        }

        function stopReplay(): string {
            RecordingService.setReplay(false);
            return "stopped";
        }

        function saveReplay(): string {
            if (!RecordingService.replayRunning) {
                return "the replay buffer is not running";
            }
            RecordingService.saveReplay();
            return "ok";
        }

        function status(): string {
            return JSON.stringify({
                recording: RecordingService.recording,
                recordingPath: RecordingService.recordingPath,
                replayRunning: RecordingService.replayRunning,
                screenshotPath: RecordingService.screenshotPath
            });
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

    Connections {
        target: LauncherService
        function onSettingsRequested() {
            settingsLoader.activeAsync = true;
        }
    }

    LazyLoader {
        id: settingsLoader
        SettingsModule.Settings {
            onClosed: settingsLoader.activeAsync = false;
        }
    }

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
