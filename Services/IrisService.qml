pragma Singleton
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root

    property string _pending: ""

    function generate(wallpaper) {
        if (!wallpaper || Config.iris.enabled === false) {
            return;
        }

        if (irisProc.running) {
            root._pending = wallpaper;
            return;
        }

        _start(wallpaper);
    }

    function _start(wallpaper) {
        root._pending = "";
        irisProc.command = ["iris", wallpaper, "--dark", Config.iris.autoMode ? "-1" : Config.iris.dark ? "1" : "0"];
        irisProc.running = true;
    }

    function _runAfter() {
        const cmd = Config.iris.after;
        if (!cmd || afterProc.running) {
            return;
        }

        // Run through a shell so quoting/pipes in the user's command work.
        afterProc.command = ["sh", "-c", cmd];
        afterProc.running = true;
    }

    Process {
        id: irisProc

        onExited: exitCode => {
            if (root._pending) {
                Qt.callLater(root._start, root._pending);
                return;
            }

            if (exitCode === 0) {
                root._runAfter();
            }
        }
    }

    Process {
        id: afterProc

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.warn("iris after command:", text);
                }
            }
        }
    }
}
