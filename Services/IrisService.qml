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
        const mode = Config.iris.autoMode ? "-1" : Config.iris.dark ? "1" : "0";
        console.log("[iris] Generating colors from", wallpaper);
        root._pending = "";
        irisProc.command = ["iris", root._toPath(wallpaper), "--dark", mode];
        irisProc.running = true;
    }

    function _toPath(wallpaper) {
        return wallpaper.toString().replace(/^file:\/\//, "");
    }

    // Commands run after a successful iris run.
    property CommandQueue after: CommandQueue {
        label: "iris"
    }

    Process {
        id: irisProc

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.warn("iris:", text);
                }
            }
        }

        onExited: exitCode => {
            if (root._pending) {
                Qt.callLater(root._start, root._pending);
                return;
            }

            if (exitCode !== 0) {
                console.warn("iris: exited with", exitCode);
                return;
            }

            // iris rendered the shell's templates into ~/.cache/iris, since
            // that is the only place it writes; copy them out to where the
            // registry wants them.
            TemplateService.installIris();
            root.after.run(Config.iris.after);
        }
    }
}
