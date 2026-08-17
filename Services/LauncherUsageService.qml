pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Core

// Tracks how often (and how recently) launcher entries are picked, so results can
// be ranked by frecency: count decayed by age, folded into the text score as a
// multiplier. State lives in the cache dir, not Config/, since it is runtime data
// rather than user settings.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/island"

    // { "<key>": { count: int, lastUsed: epochSeconds } }
    // Always reassigned wholesale, never mutated in place, so bindings re-evaluate.
    property var stats: ({})

    // Below this frecency an entry is dropped on save, so the file can't grow forever.
    readonly property real pruneThreshold: 0.05

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.dir])

    FileView {
        id: file
        path: root.dir + "/launcher-usage.json"
        watchChanges: false
        // Missing file is the normal first-run case, not worth a warning.
        printErrors: false
        onLoaded: {
            try {
                root.stats = JSON.parse(text()) ?? ({});
            } catch (e) {
                root.stats = ({});
            }
        }
        onLoadFailed: root.stats = ({})
        // The cache dir is created asynchronously at startup, so the very first
        // save can lose the race. Recreate it and retry once.
        onSaveFailed: {
            if (root.retriedSave)
                return;
            root.retriedSave = true;
            Quickshell.execDetached(["mkdir", "-p", root.dir]);
            saveTimer.restart();
        }
    }

    property bool retriedSave: false

    // Stable identity for an entry. DesktopEntry carries a real `id`; plain provider
    // entries fall back to a provider-scoped name so the same label under different
    // providers doesn't share a counter.
    function key(entry, providerId) {
        if (!entry)
            return "";
        return entry.usageKey ?? entry.id ?? (providerId + ":" + entry.name);
    }

    function frecency(key) {
        const stat = root.stats[key];
        if (!stat)
            return 0;

        const ageDays = (Date.now() / 1000 - stat.lastUsed) / 86400;
        return stat.count * Math.pow(0.5, ageDays / Config.launcher.usageHalfLifeDays);
    }

    // Score multiplier: 1 for unseen entries, so a zero text score stays zero and
    // nothing that doesn't match can be boosted into the results.
    function boost(key) {
        if (!Config.launcher.sortByUsage)
            return 1;
        return 1 + Config.launcher.usageWeight * Math.log(1 + frecency(key));
    }

    function record(key) {
        if (!key)
            return;

        const next = Object.assign({}, root.stats);
        const stat = next[key];
        next[key] = {
            count: (stat?.count ?? 0) + 1,
            lastUsed: Math.round(Date.now() / 1000)
        };
        root.stats = next;
        saveTimer.restart();
    }

    // Coalesce bursts of launches into one write.
    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.save()
    }

    function save() {
        const kept = {};
        for (const key in root.stats)
            if (root.frecency(key) >= root.pruneThreshold)
                kept[key] = root.stats[key];

        root.stats = kept;
        file.setText(JSON.stringify(kept));
    }
}
