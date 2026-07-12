pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    property NotificationServer server: NotificationServer {
        id: server
        actionsSupported: true
        keepOnReload: false
    }

    function notify(summary, body) {
        notifyProc.command = ["notify-send", "--app-name=Quickshell", summary, body];
        notifyProc.running = true;
    }

    Process {
        id: notifyProc
    }
}
