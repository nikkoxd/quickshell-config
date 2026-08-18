pragma Singleton
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root

    property string _pending: ""

    // Wallpaper the luminance probe is running for, when autoMode is on.
    property string _probing: ""

    function generate(wallpaper) {
        if (!wallpaper || Config.theme.colorscheme !== "Matugen") {
            return;
        }

        if (matugenProc.running || probeProc.running) {
            root._pending = wallpaper;
            return;
        }

        if (Config.matugen.autoMode) {
            _probe(wallpaper);
        } else {
            _start(wallpaper, Config.matugen.dark ? "dark" : "light");
        }
    }

    // matugen has no auto light/dark mode, so pick one from the source color it
    // would extract. --dry-run renders no templates and runs no commands.
    function _probe(wallpaper) {
        root._pending = "";
        root._probing = wallpaper;
        probeProc.command = _command(wallpaper, "dark").concat(["--dry-run"]);
        probeProc.running = true;
    }

    function _start(wallpaper, mode) {
        console.log("[matugen] Generating", mode, "colors from", wallpaper);
        root._pending = "";
        matugenProc.command = _command(wallpaper, mode);
        matugenProc.running = true;
    }

    function _command(wallpaper, mode) {
        const cmd = ["matugen", "image", root._toPath(wallpaper), "-m", mode, "-t", Config.matugen.scheme, "--prefer", Config.matugen.prefer, "-j", "hex", "-q"];

        // matugen treats any --contrast as an override, so only pass a non-default one.
        if (Config.matugen.contrast !== 0) {
            cmd.push("--contrast", String(Config.matugen.contrast));
        }

        return cmd;
    }

    function _toPath(wallpaper) {
        return wallpaper.toString().replace(/^file:\/\//, "");
    }

    function _color(colors, name) {
        const entry = colors[name];
        if (!entry) {
            return undefined;
        }

        // "default" follows the mode passed with -m.
        return (entry.default || entry.dark || entry.light || {}).color;
    }

    // Relative luminance of a #rrggbb string, 0..1.
    function _luminance(hex) {
        const c = String(hex).replace("#", "");
        if (c.length < 6) {
            return 0;
        }

        const r = parseInt(c.substring(0, 2), 16) / 255;
        const g = parseInt(c.substring(2, 4), 16) / 255;
        const b = parseInt(c.substring(4, 6), 16) / 255;
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    function _writeColorscheme(json) {
        var parsed;
        try {
            parsed = JSON.parse(json);
        } catch (e) {
            console.warn("matugen: could not parse color json:", e);
            return;
        }

        const colors = parsed.colors;
        if (!colors) {
            console.warn("matugen: color json has no colors object");
            return;
        }

        const bg = root._color(colors, "surface");
        const surface = root._color(colors, "surface_container_high");
        const fg = root._color(colors, "on_surface");
        const dim = root._color(colors, "outline");
        const accent = root._color(colors, "primary");
        const accentAlt = root._color(colors, "primary_container");

        if (!bg || !surface || !fg || !dim || !accent || !accentAlt) {
            console.warn("matugen: color json is missing expected colors");
            return;
        }

        colorschemeFile.adapter.bg = bg;
        colorschemeFile.adapter.surface = surface;
        colorschemeFile.adapter.fg = fg;
        colorschemeFile.adapter.dim = dim;
        colorschemeFile.adapter.accent = accent;
        colorschemeFile.adapter.accentAlt = accentAlt;
        colorschemeFile.writeAdapter();
    }

    // Commands run after a successful matugen run.
    property CommandQueue after: CommandQueue {
        label: "matugen"
    }

    Process {
        id: probeProc

        stdout: StdioCollector {
            id: probeOutput
        }

        onExited: exitCode => {
            const wallpaper = root._probing;
            root._probing = "";

            if (root._pending) {
                // Clear first: generate() re-queues into _pending otherwise.
                const pending = root._pending;
                root._pending = "";
                Qt.callLater(() => root.generate(pending));
                return;
            }

            if (exitCode !== 0 || !wallpaper) {
                return;
            }

            var mode = Config.matugen.dark ? "dark" : "light";
            try {
                const colors = JSON.parse(probeOutput.text).colors;
                const source = root._color(colors, "source_color");
                if (source) {
                    mode = root._luminance(source) > 0.5 ? "light" : "dark";
                }
            } catch (e) {
                console.warn("matugen: could not parse probe json:", e);
            }

            root._start(wallpaper, mode);
        }
    }

    Process {
        id: matugenProc

        stdout: StdioCollector {
            id: matugenOutput
        }

        onExited: exitCode => {
            if (root._pending) {
                // Clear first: generate() re-queues into _pending otherwise.
                const pending = root._pending;
                root._pending = "";
                Qt.callLater(() => root.generate(pending));
                return;
            }

            if (exitCode !== 0) {
                return;
            }

            if (Config.matugen.writeColorscheme) {
                root._writeColorscheme(matugenOutput.text);
            }

            root.after.run(Config.matugen.after);
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.warn("matugen:", text);
                }
            }
        }
    }

    FileView {
        id: colorschemeFile

        path: Qt.resolvedUrl("../Themes/Matugen.json")

        adapter: JsonAdapter {
            property string bg: "#080808"
            property string surface: "#313131"
            property string fg: "#dadada"
            property string dim: "#555555"
            property string accent: "#bfad9e"
            property string accentAlt: "#5f4d3e"
        }
    }
}
