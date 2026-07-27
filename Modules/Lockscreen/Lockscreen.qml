import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root

    IpcHandler {
        target: "lockscreen"
        function lock() {
            lockscreen.locked = true;
        }
    }

    LockscreenContext {
        id: lockContext
        onUnlockRequested: pam.start();
        onUnlocked: lockscreen.locked = false;
    }

    PamContext {
        id: pam
        configDirectory: "."
        config: "password.conf"
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(lockContext.currentText);
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                lockContext.unlocked();
            } else {
                console.log("Failed!");
            }
            lockContext.currentText = "";
        }
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    WlSessionLock {
        id: lockscreen
        locked: false

        LockscreenSurface {
            id: lockSurface
            context: lockContext
        }
    }
}
