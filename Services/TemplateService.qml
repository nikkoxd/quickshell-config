pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Core

// Owns the app-theming templates shared by the Iris and Matugen generators.
//
// Templates/Iris/<file> and Templates/Matugen/<file> are two renderings of the
// same target file. The registry in Config/templates.json says where each one
// is written and what to run afterwards, so both generators produce the same
// paths and theme names — switching generators needs no change inside Discord,
// Telegram, Emacs, ghostty or Qt.
//
// Neither generator can be pointed at an arbitrary output on its own, so each
// gets its own shim:
//
//   Matugen renders its own templates, so this service keeps a generated
//   Config/matugen-config.toml in sync with the registry.
//
//   Iris hardcodes both ends — it renders ~/.config/iris/templates/X into
//   ~/.cache/iris/X and nothing else. So the templates are symlinked into that
//   directory and the results are copied out of the cache afterwards. Iris does
//   all the rendering; the shell only moves files.
Singleton {
    id: root

    readonly property string _root: Qt.resolvedUrl("..").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
    readonly property string matugenConfigPath: root._root + "/Config/matugen-config.toml"
    readonly property string registryPath: root._root + "/Config/templates.json"

    // Registry keys, in the order they appear in Config/templates.json.
    readonly property var names: Object.keys(Config.templates || {})

    // A registry entry with its defaults filled in.
    function entry(name) {
        const raw = (Config.templates || {})[name] || {};
        return {
            name: name,
            enabled: raw.enabled !== false,
            template: raw.template || name,
            output: raw.output || "",
            postHook: raw.postHook || ""
        };
    }

    function enabledEntries() {
        return root.names.map(root.entry).filter(e => e.enabled && e.output);
    }

    function templatePath(generator, template) {
        return root._root + "/Templates/" + generator + "/" + template;
    }

    // {generator} -> Iris/Matugen, {mode} -> dark/light.
    function _expand(text, generator, mode) {
        return String(text).replace(/\{generator\}/g, generator).replace(/\{mode\}/g, mode);
    }

    // Post hooks run from the shell for both generators, so an enabled
    // template behaves the same whichever one produced it.
    function runPostHooks(generator, mode) {
        const cmds = root.enabledEntries().map(e => root._expand(e.postHook, generator, mode)).filter(cmd => cmd);
        root.hooks.run(cmds);
    }

    property CommandQueue hooks: CommandQueue {
        label: "templates"
    }

    // Opens Config/templates.json in whatever handles JSON. Everything but the
    // enabled toggle is edited there; the file is watched, so a save applies.
    function openRegistry() {
        editorProc.command = ["xdg-open", root.registryPath];
        editorProc.running = true;
    }

    Process {
        id: editorProc

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.warn("templates: could not open registry:", text);
                }
            }
        }
    }

    // --- Matugen -------------------------------------------------------

    function _matugenConfig(base) {
        const sections = [base.replace(/\s*$/, ""), ""];

        for (const e of root.enabledEntries()) {
            // Matugen has no {generator} of its own; it is always Matugen here.
            // {mode} is left to matugen's own {{mode}} handling in the template.
            sections.push("[templates." + e.name + "]");
            sections.push("input_path = '" + root.templatePath("Matugen", e.template) + "'");
            sections.push("output_path = '" + root._expand(e.output, "Matugen", "{{mode}}") + "'");
            sections.push("");
        }

        return sections.join("\n");
    }

    // --- Iris ----------------------------------------------------------

    readonly property string _home: Quickshell.env("HOME") || ""
    readonly property string irisTemplateDir: root._home + "/.config/iris/templates"
    readonly property string irisCacheDir: root._home + "/.cache/iris"

    // Whether iris rendered dark colors, straight from its own output rather
    // than guessed. Seeded from the config so {mode} is never empty before the
    // first run.
    property bool _irisDark: Config.iris.dark

    // Points ~/.config/iris/templates at Templates/Iris, since that is the only
    // directory iris reads. Prune-then-relink keeps it stateless; -type l with
    // -lname means only links this service made are removed, never the user's
    // own files in there.
    function syncIris() {
        const dir = root.irisTemplateDir;
        const source = root._root + "/Templates/Iris";
        const cmds = [`mkdir -p ${root._quote(dir)}`, `find ${root._quote(dir)} -maxdepth 1 -type l -lname ${root._quote(source + "/*")} -delete`];

        // Several entries can share one template file (gtk3/gtk4 both use
        // gtk.css), and one link is enough.
        const linked = [];
        for (const e of root.enabledEntries()) {
            if (linked.includes(e.template)) {
                continue;
            }

            linked.push(e.template);
            cmds.push(`ln -sfn ${root._quote(source + "/" + e.template)} ${root._quote(dir + "/" + e.template)}`);
        }

        root.sync.run(cmds);
    }

    // Copies what iris just rendered into the cache out to the configured
    // outputs, then runs the post hooks. Called after a successful iris run.
    function installIris() {
        const mode = root._irisDark ? "dark" : "light";
        const cmds = [];

        for (const e of root.enabledEntries()) {
            const output = root._quote(root._expand(e.output, "Iris", mode));
            const cached = root._quote(root.irisCacheDir + "/" + e.template);
            cmds.push(`mkdir -p "$(dirname ${output})" && cp -f ${cached} ${output}`);
        }

        for (const e of root.enabledEntries()) {
            const hook = root._expand(e.postHook, "Iris", mode);
            if (hook) {
                cmds.push(hook);
            }
        }

        root.hooks.run(cmds);
    }

    // Commands go through a shell, so paths need quoting. Registry paths may
    // still start with ~, which has to stay outside the quotes to expand.
    function _quote(path) {
        const text = String(path).replace(/"/g, "");
        return text.startsWith("~/") ? '~/"' + text.substring(2) + '"' : '"' + text + '"';
    }

    property CommandQueue sync: CommandQueue {
        label: "templates"
    }

    // Iris records the mode it chose, so {mode} does not have to be guessed
    // back out of the colors. Read opportunistically: installIris() must never
    // wait on a file signal, or a run with unchanged colors would stall.
    FileView {
        id: irisColorsFile
        path: root.irisCacheDir + "/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root._irisDark = JSON.parse(text()).dark !== false;
            } catch (e) {
                console.warn("templates: could not parse iris colors:", e);
            }
        }
    }

    // --- Generated matugen config --------------------------------------

    FileView {
        id: matugenBaseFile
        path: root._root + "/Templates/matugen-base.toml"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: matugenConfigFile.setText(root._matugenConfig(text()))
    }

    FileView {
        id: matugenConfigFile
        path: root.matugenConfigPath
        // Write-only: it is generated here, never read back.
        printErrors: false
        onSaveFailed: error => console.warn("templates: could not write matugen config:", error)
    }

    function _regenerateMatugenConfig() {
        const base = matugenBaseFile.text();
        if (base) {
            matugenConfigFile.setText(root._matugenConfig(base));
        }
    }

    // Both generators need their notion of "what to render" refreshed whenever
    // the registry changes: matugen through its config, iris through the
    // symlinks in the only directory it reads.
    Connections {
        target: Config
        function onTemplatesChanged() {
            root._regenerateMatugenConfig();
            root.syncIris();
        }
    }

    // Singletons load lazily, so by the time something first reaches for this
    // one the registry has usually already loaded and its change signal is long
    // gone. Sync once on creation to cover that.
    Component.onCompleted: {
        root._regenerateMatugenConfig();
        root.syncIris();
    }
}
