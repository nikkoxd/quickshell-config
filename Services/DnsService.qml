pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

// Switches the DNS servers of the active NetworkManager connection.
//
// Everything goes through nmcli: the presets in Config/dns.json are written to
// the connection profile (ipv4.dns/ipv6.dns plus ignore-auto-dns) and the
// connection is brought up again so the change reaches resolv.conf. Nothing is
// stored about "which preset is selected" -- the answer is read back out of the
// profile, so a change made behind the shell's back still shows up here.
Singleton {
    id: root

    // The DHCP-provided servers, always offered as the first entry.
    readonly property var automaticEntry: ({
            name: "Automatic (DHCP)",
            ipv4: [],
            ipv6: [],
            automatic: true
        })

    readonly property var entries: [root.automaticEntry].concat(Config.dns || [])

    // Active connection the presets are applied to.
    property string connectionName: ""
    property string connectionUuid: ""

    // Servers currently configured on that connection.
    property var currentIpv4: []
    property var currentIpv6: []
    property bool ignoreAutoDns: false

    // Name of the entry matching the connection, "" when nothing matches
    // (someone set servers by hand, or the preset was edited since).
    readonly property string currentName: {
        for (let i = 0; i < root.entries.length; i++) {
            if (root.matches(root.entries[i]))
                return root.entries[i].name;
        }
        return "";
    }

    property bool busy: false
    property string error: ""

    // Steps left in the current apply(), each { args, optional }.
    property var _queue: []
    // Preset being applied, kept only for the failure message.
    property string _pending: ""

    function matches(entry) {
        if (entry.automatic)
            return !root.ignoreAutoDns && root.currentIpv4.length === 0;
        if (!root.ignoreAutoDns)
            return false;
        if (!root._sameList(entry.ipv4, root.currentIpv4))
            return false;
        // A connection with ipv6 disabled rejects ipv6.dns, so a preset counts
        // as applied when only its ipv4 half made it through.
        return root.currentIpv6.length === 0 || root._sameList(entry.ipv6, root.currentIpv6);
    }

    function _sameList(a, b) {
        const left = (a || []).filter(v => v !== "");
        const right = (b || []).filter(v => v !== "");
        if (left.length !== right.length)
            return false;
        return left.every(v => right.indexOf(v) !== -1);
    }

    function refresh() {
        activeProc.running = true;
    }

    function apply(entry) {
        if (root.busy)
            return;
        if (root.connectionUuid === "") {
            root.error = "No active connection";
            NotificationService.notify("DNS", "No active NetworkManager connection to configure");
            return;
        }

        const automatic = entry.automatic === true;
        const ipv4 = automatic ? [] : (entry.ipv4 || []).filter(v => v !== "");
        const ipv6 = automatic ? [] : (entry.ipv6 || []).filter(v => v !== "");

        root.error = "";
        root._pending = entry.name;
        root.busy = true;
        root._queue = [
            {
                args: ["connection", "modify", root.connectionUuid, "ipv4.dns", ipv4.join(","), "ipv4.ignore-auto-dns", ipv4.length > 0 ? "yes" : "no"],
                optional: false
            },
            // ipv6 is a separate step because it is rejected outright when the
            // connection has ipv6 disabled -- an ipv4-only preset should still
            // apply on such a connection.
            {
                args: ["connection", "modify", root.connectionUuid, "ipv6.dns", ipv6.join(","), "ipv6.ignore-auto-dns", ipv6.length > 0 ? "yes" : "no"],
                optional: true
            },
            {
                args: ["connection", "up", root.connectionUuid],
                optional: false
            }
        ];
        root._runNext();
    }

    function _runNext() {
        if (root._queue.length === 0) {
            root.busy = false;
            root._pending = "";
            root.refresh();
            return;
        }

        const step = root._queue.shift();
        applyProc.optional = step.optional;
        applyProc.command = ["nmcli"].concat(step.args);
        applyProc.running = true;
    }

    function _fail(message) {
        root.busy = false;
        root._queue = [];
        root.error = message;
        NotificationService.notify("DNS", "Could not switch to " + root._pending + ": " + message);
        root._pending = "";
        root.refresh();
    }

    Component.onCompleted: root.refresh()

    // A real uplink first (ethernet, then wifi); anything that is not a
    // loopback, bridge or tunnel as a fallback. Docker bridges and VPN tunnels
    // are active connections too, and resolve ahead of the uplink in nmcli's
    // own order.
    readonly property var _preferredTypes: ["802-3-ethernet", "802-11-wireless"]
    readonly property var _skippedTypes: ["loopback", "bridge", "tun", "vpn", "wireguard"]

    // NAME:UUID:TYPE for every active connection.
    Process {
        id: activeProc
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE", "connection", "show", "--active"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l !== "");
                let candidates = [];
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":");
                    if (parts.length < 3 || root._skippedTypes.indexOf(parts[2]) !== -1)
                        continue;
                    candidates.push(parts);
                }

                let chosen = candidates.find(c => root._preferredTypes.indexOf(c[2]) !== -1) || candidates[0];
                if (chosen) {
                    root.connectionName = chosen[0];
                    root.connectionUuid = chosen[1];
                    dnsProc.running = true;
                    return;
                }
                root.connectionName = "";
                root.connectionUuid = "";
                root.currentIpv4 = [];
                root.currentIpv6 = [];
                root.ignoreAutoDns = false;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text)
                    console.warn("[dns] listing connections:", text);
            }
        }
    }

    Process {
        id: dnsProc
        command: ["nmcli", "-t", "-f", "ipv4.dns,ipv6.dns,ipv4.ignore-auto-dns", "connection", "show", root.connectionUuid]

        stdout: StdioCollector {
            onStreamFinished: {
                let ipv4 = [];
                let ipv6 = [];
                let ignore = false;
                const lines = text.split("\n").filter(l => l !== "");
                for (let i = 0; i < lines.length; i++) {
                    const split = lines[i].indexOf(":");
                    if (split === -1)
                        continue;
                    const key = lines[i].slice(0, split);
                    const value = lines[i].slice(split + 1);
                    const list = value.split(",").map(v => v.trim()).filter(v => v !== "" && v !== "--");
                    if (key === "ipv4.dns")
                        ipv4 = list;
                    else if (key === "ipv6.dns")
                        ipv6 = list;
                    else if (key === "ipv4.ignore-auto-dns")
                        ignore = value === "yes";
                }
                root.currentIpv4 = ipv4;
                root.currentIpv6 = ipv6;
                root.ignoreAutoDns = ignore;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text)
                    console.warn("[dns] reading connection:", text);
            }
        }
    }

    Process {
        id: applyProc

        // Set per step: a failing optional step is warned about and skipped.
        property bool optional: false
        property string lastError: ""

        onExited: exitCode => {
            if (exitCode === 0) {
                root._runNext();
                return;
            }
            if (applyProc.optional) {
                console.warn("[dns] skipping step:", applyProc.lastError);
                root._runNext();
                return;
            }
            root._fail(applyProc.lastError || ("nmcli exited with " + exitCode));
        }

        stderr: StdioCollector {
            onStreamFinished: {
                applyProc.lastError = text.trim().split("\n").pop() || "";
            }
        }
    }
}
