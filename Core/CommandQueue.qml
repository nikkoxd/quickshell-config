import QtQml
import Quickshell.Io

// Runs a list of shell commands one at a time, in order.
QtObject {
    id: root

    // Prefix for warnings about command output.
    property string label: ""

    // Commands left to run, in order.
    property var _queue: []

    function run(cmds) {
        if (!cmds || cmds.length === 0 || proc.running) {
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
            proc.command = ["sh", "-c", cmd];
            proc.running = true;
            return;
        }
    }

    property Process proc: Process {
        onExited: root._runNext()

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.warn(root.label, "after command:", text);
                }
            }
        }
    }
}
