pragma Singleton
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root

    property string _pending: ""

    // Commands left to run after the last successful iris run, in order.
    property var _queue: []

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
        const cmds = Config.iris.after;
        if (!cmds || cmds.length === 0 || afterProc.running) {
            return;
        }

        root._queue = Array.from(cmds);
        root._runNext();
    }

    function _runNext() {
        const queue = root._queue;
        while (queue.length > 0) {
            const cmd = queue.shift();
            if (!cmd) {
                continue;
            }

            // Run through a shell so quoting/pipes in the user's command work.
            afterProc.command = ["sh", "-c", cmd];
            afterProc.running = true;
            return;
        }
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

        onExited: root._runNext()

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.warn("iris after command:", text);
                }
            }
        }
    }
}
