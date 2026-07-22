pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var entries: []

    function startListener() {
        listenProc.running = true;
    }

    function fetch() {
        console.log("[cliphist] Fetching clipboard history");
        listProc.running = true;
    }

    function wipe() {
        wipeProc.running = true;
    }

    function decodeAndCopy(id) {
        decodeProc.command = ["cliphist", "decode", id];
        decodeProc.running = true;
    }

    Process {
        id: listenProc
        command: ["wl-paste", "--watch", "cliphist", "store"]
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.split("\n");

                root.entries = [];
                for (let i = 0; i < out.length; i++) {
                    const [id, value] = out[i].split("\t");
                    if (id === undefined || value === undefined) continue;
                    root.entries.push({
                        name: value,
                        execute: function() {
                            root.decodeAndCopy(id);
                        }
                    });
                }
            }
        }
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
    }

    Process {
        id: decodeProc
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[cliphist] Copying text:", this.text);
                Quickshell.execDetached(["wl-copy", this.text]);
            }
        }
    }
}
