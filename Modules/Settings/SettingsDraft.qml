pragma Singleton
import Quickshell
import QtQuick
import qs.Core

// Edits made in the settings window, held back until they are saved. Pages
// read every value through get(), so a control shows what was entered rather
// than what is on disk, and write through set() instead of assigning to Config.
//
// A value is addressed by its Config group and key (`"island", "height"`). The
// groups Config parses by hand (templates, dns) are staged whole, with no key,
// and saved through their own Config.save* function.
Singleton {
    id: root

    // "<group>.<key>" -> { group, key, value }. Replaced rather than mutated,
    // so every binding that went through get() re-evaluates.
    property var pending: ({})
    readonly property int count: Object.keys(root.pending).length
    readonly property bool dirty: root.count > 0

    readonly property var savers: ({
            templates: value => Config.saveTemplates(value),
            dns: value => Config.saveDns(value)
        })

    function _id(group, key) {
        return key ? group + "." + key : group;
    }

    function _current(group, key) {
        const source = Config[group];
        return key ? source?.[key] : source;
    }

    function _same(a, b) {
        return a === b || JSON.stringify(a) === JSON.stringify(b);
    }

    function get(group, key) {
        const entry = root.pending[root._id(group, key)];
        return entry !== undefined ? entry.value : root._current(group, key);
    }

    // Setting a value back to what is saved drops it from the draft, so
    // undoing an edit by hand leaves nothing to save.
    function set(group, key, value) {
        const id = root._id(group, key);
        const next = Object.assign({}, root.pending);
        if (root._same(value, root._current(group, key)))
            delete next[id];
        else
            next[id] = {
                group: group,
                key: key,
                value: value
            };
        root.pending = next;
    }

    function save() {
        const entries = Object.values(root.pending);
        root.pending = {};
        for (const entry of entries) {
            if (!entry.key)
                root.savers[entry.group](entry.value);
            else
                Config[entry.group][entry.key] = entry.value;
        }
    }

    function discard() {
        root.pending = {};
    }
}
