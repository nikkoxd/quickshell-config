pragma Singleton

import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
    id: root

    property bool locked: true
    property var entries: []
    property string _master: ""

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

    function copy(path) {
        clipProc.command = ["keepassxc-cli", "clip", Config.island.keepassVault, path];
        clipProc.running = true;
    }

    Process {
        id: listProc
        command: ["keepassxc-cli", "ls", Config.island.keepassVault]
        stdinEnabled: true
        onStarted: write(root._master + "\n")
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = this.text.split("\n");

                root.entries = [];
                for (let i = 0; i < paths.length; i++) {
                    entries.push({
                        name: paths[i],
                        execute: function() {
                            root.copy(paths[i]);
                        }
                    })
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("[keepassxc] Unlock failed")
                root.unlockFailed();
            } else {
                console.log("[keepassxc] Vault unlocked")
                root.locked = false;
            }
        }
    }

    Process {
        id: clipProc
        onStarted: write(root._master + "\n")
    }
}
