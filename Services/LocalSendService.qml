pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var devices: []
    property real progress: 0.0 // not used, maybe display it in the ui

    signal discoveryFinished(int count)
    signal sendFinished(bool success)
    signal prepareUploadReceived(var transferData)
    signal transferCancelled
    signal transferDone

    function startDiscovery() {
        discoverProc.running = true;
    }

    function send(files, device) {
        sendProc.command = ["localsend-cli", "send", "--to", device.ip + ":" + device.port, "--json"];
        for (let i = 0; i < files.length; i++) {
            const prefix = "file://";
            let file = files[i];
            if (file.startsWith(prefix)) {
                file = file.substring(prefix.length);
            }
            sendProc.command.push(file);
        }
        console.log(sendProc.command);
        sendProc.running = true;
    }

    function acceptTransfer() {
        if (serverProc.running) {
            console.log("Accepting transfer");
            serverProc.write("yes\n");
        }
    }

    function rejectTransfer() {
        if (serverProc.running) {
            console.log("[localsend] Rejecting transfer");
            serverProc.write("no\n");
        }
    }

    Process {
        id: discoverProc
        command: ["localsend-cli", "discover", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text;
                let jsonStart = raw.indexOf('{');
                if (jsonStart !== -1) {
                    raw = raw.substring(jsonStart);
                }
                let jsonEnd = raw.lastIndexOf('}');
                if (jsonEnd !== -1) {
                    raw = raw.substring(0, jsonEnd + 1);
                }

                try {
                    let response = JSON.parse(raw);
                    root.devices = response.devices || [];
                    root.discoveryFinished(response.count);
                    console.log("Found", response.count, "devices");
                } catch (e) {
                    root.discoveryFinished(0);
                    console.error("Failed to parse JSON:", e);
                }
            }
        }
    }

    Process {
        id: sendProc
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text;
                let jsonStart = raw.indexOf('{');
                if (jsonStart !== -1) {
                    raw = raw.substring(jsonStart);
                }
                let jsonEnd = raw.lastIndexOf('}');
                if (jsonEnd !== -1) {
                    raw = raw.substring(0, jsonEnd + 1);
                }

                try {
                    let response = JSON.parse(raw);
                    root.sendFinished(response.success);
                } catch (e) {
                    root.sendFinished(false);
                    console.error("Failed to parse JSON:", e);
                }
            }
        }
    }

    Process {
        id: serverProc
        running: true
        stdinEnabled: true
        command: ["localsend-cli", "receive", "--json"]
        stdout: SplitParser {
            onRead: data => {
                // cancellation
                if (data.indexOf("Transfer cancelled by sender") !== -1) {
                    root.progress = 0.0;
                    root.transferCancelled();
                    return;
                }
                // new transfer announcement
                if (data.startsWith("{")) {
                    try {
                        const tx = JSON.parse(data);
                        root.prepareUploadReceived(tx);
                    } catch (e) {
                        console.error("Failed to parse JSON:", e);
                    }
                    return;
                }
                // progress update
                const progressRe = /(?:\[INFO\]\s+)?\s*(.+?):\s+([\d.]+)%\s+\((\d+)\/(\d+)\s+bytes\)/;
                const pMatch = progressRe.exec(data);
                if (pMatch) {
                    root.progress = parseFloat(pMatch[2]) / 100.0;
                    return;
                }
                // transfer done
                const doneRe = /(?:\[INFO\]\s+)?Received:\s+(.+?)\s+\((\d+)\s+bytes\)/;
                const dMatch = doneRe.exec(data);
                if (dMatch) {
                    root.transferDone();
                    root.progress = 0.0;
                    return;
                }
                console.log("[localsend]", data);
            }
        }
    }
}
