pragma Singleton

import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root

    property bool locked: true
    property var entries: []
    property string _master: ""
    property var _paths: []
    property var _logins: ({})

    signal unlockFailed()

    function unlock(password) {
        root._master = password;
        listProc.running = true;
    }

    function lock() {
        root._master = "";
        root.locked = true;
    }

    function list() {
        listProc.running = true;
    }

    // Rebuild the entry list from the paths and whatever logins are known by now.
    function _build() {
        root.entries = root._paths.map(path => ({
            name: path,
            genericName: root._logins[path] || "",
            execute: function() {
                root.copy(path);
            }
        }));
    }

    // Minimal CSV reader: quoted fields, "" escapes and newlines inside quotes.
    function _parseCsv(text) {
        const rows = [];
        let row = [], field = "", quoted = false;
        for (let i = 0; i < text.length; i++) {
            const c = text[i];
            if (quoted) {
                if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
                else if (c === '"') quoted = false;
                else field += c;
            } else if (c === '"') quoted = true;
            else if (c === ",") { row.push(field); field = ""; }
            else if (c === "\n") { row.push(field); rows.push(row); row = []; field = ""; }
            else if (c !== "\r") field += c;
        }
        if (field !== "" || row.length) { row.push(field); rows.push(row); }
        return rows;
    }

    function copy(path) {
        clipProc.command = ["keepassxc-cli", "clip", Config.launcher.keepassVault, path];
        clipProc.running = true;
    }

    Process {
        id: listProc
        command: ["keepassxc-cli", "ls", Config.launcher.keepassVault]
        stdinEnabled: true
        onStarted: write(root._master + "\n")
        stdout: StdioCollector {
            onStreamFinished: {
                root._paths = this.text.split("\n");
                root._build();
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("[keepassxc] Unlock failed")
                root.unlockFailed();
            } else {
                console.log("[keepassxc] Vault unlocked")
                root.locked = false;
                loginProc.running = true;
            }
        }
    }

    Process {
        id: clipProc
        onStarted: write(root._master + "\n")
    }

    // One export reads every username at once; `show` per entry would derive
    // the key again each time. Only the Username column is kept.
    Process {
        id: loginProc
        command: ["keepassxc-cli", "export", "-q", "-f", "csv", Config.launcher.keepassVault]
        stdinEnabled: true
        onStarted: write(root._master + "\n")
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = root._parseCsv(this.text);
                const head = rows.shift() || [];
                const g = head.indexOf("Group"), t = head.indexOf("Title"), u = head.indexOf("Username");
                if (g < 0 || t < 0 || u < 0)
                    return;
                const logins = {};
                for (const r of rows) {
                    if (!r[u])
                        continue;
                    // The first segment is the vault's root group, whatever it is named
                    // ("Passwords" here), which `ls` leaves out of its paths.
                    const group = (r[g] || "").split("/").slice(1).join("/");
                    logins[group ? group + "/" + r[t] : r[t]] = r[u];
                }
                root._logins = logins;
                root._build();
            }
        }
    }
}
