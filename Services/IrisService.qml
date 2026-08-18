pragma Singleton
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root

    property string _pending: ""

    function generate(wallpaper) {
        if (!wallpaper || Config.theme.colorscheme !== "Iris") {
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

    // Commands run after a successful iris run.
    property CommandQueue after: CommandQueue {
        label: "iris"
    }

    Process {
        id: irisProc

        onExited: exitCode => {
            if (root._pending) {
                Qt.callLater(root._start, root._pending);
                return;
            }

            if (exitCode === 0) {
                root.after.run(Config.iris.after);
            }
        }
    }
}
