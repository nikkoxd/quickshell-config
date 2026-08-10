pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Core

Singleton {
    id: root

    // One dock item per application, in display order: pinned apps (ordered by
    // Config.dock.pinned) plus every running app that isn't pinned.
    // Item shape: { appId, entry, toplevels, pinned }.
    property var items: []

    // Display order of app ids, running-but-unpinned apps included. Only the
    // pinned part of it is saved, so unpinned apps fall back to window order
    // after a restart.
    property var order: []

    readonly property var pinned: Config.dock?.pinned ?? []

    // Last list we wrote ourselves. Used to tell our own save (which is echoed
    // back once the FileView reloads the file) from the config being loaded at
    // startup or edited by hand.
    property var lastSaved: null

    onPinnedChanged: {
        // The pinned list arrives after the first windows do — Config's FileView
        // loads asynchronously — so a list that didn't come from us has to win
        // here, otherwise the dock keeps whatever order the toplevels happened
        // to show up in and the saved positions are lost.
        const saved = Array.from(root.pinned);
        if (!sameOrder(saved, root.lastSaved)) {
            root.lastSaved = saved;
            root.order = saved.concat(root.order.filter(appId => saved.indexOf(appId) === -1));
        }
        root.rebuild();
    }

    function sameOrder(a, b) {
        return !!a && !!b && a.length === b.length && a.every((appId, i) => appId === b[i]);
    }

    function itemFor(appId) {
        return root.items.find(item => item.appId === appId) ?? null;
    }

    function isPinned(appId) {
        for (let i = 0; i < root.pinned.length; i++)
            if (root.pinned[i] === appId)
                return true;
        return false;
    }

    function setPinned(appId, pinned) {
        if (!appId || pinned === isPinned(appId))
            return;

        const wanted = Array.from(root.pinned);
        if (pinned)
            wanted.push(appId);
        else
            wanted.splice(wanted.indexOf(appId), 1);

        // Save in on-screen order so pinning doesn't shuffle the dock.
        const ordered = root.order.filter(id => wanted.indexOf(id) !== -1);
        save(ordered.concat(wanted.filter(id => ordered.indexOf(id) === -1)));
    }

    function save(pinned) {
        root.lastSaved = pinned;
        Config.dock.pinned = pinned;
    }

    function togglePin(appId) {
        setPinned(appId, !isPinned(appId));
    }

    // Reorder live (during a drag). Call persistOrder() once the drag ends;
    // writing on every step would rewrite dock.json dozens of times.
    function move(from, to) {
        const ordered = Array.from(root.order);
        if (from === to || from < 0 || to < 0 || from >= ordered.length || to >= ordered.length)
            return;

        ordered.splice(to, 0, ordered.splice(from, 1)[0]);
        root.order = ordered;
        root.rebuild();
    }

    function persistOrder() {
        const ordered = root.order.filter(id => root.isPinned(id));
        const saved = Array.from(root.pinned);
        if (ordered.length === saved.length && ordered.every((id, i) => id === saved[i]))
            return;
        save(ordered);
    }

    // Left click: focus the app, cycling through its windows when it has more
    // than one; launch it when nothing of it is running.
    function activate(item) {
        const windows = item?.toplevels ?? [];
        if (windows.length === 0) {
            launch(item);
            return;
        }

        let next = 0;
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].activated) {
                next = (i + 1) % windows.length;
                break;
            }
        }
        windows[next].activate();
    }

    function launch(item) {
        if (item?.entry)
            item.entry.execute();
    }

    function close(item) {
        for (const toplevel of item?.toplevels ?? [])
            toplevel.close();
    }

    function rebuild() {
        // Map, not an object literal: app ids like "constructor" would hit
        // Object.prototype and look like existing groups.
        const groups = new Map();
        const running = [];

        for (const toplevel of ToplevelManager.toplevels.values) {
            const appId = toplevel.appId;
            if (!appId)
                continue;
            if (!groups.has(appId)) {
                groups.set(appId, []);
                running.push(appId);
            }
            groups.get(appId).push(toplevel);
        }

        const pinnedIds = Array.from(root.pinned);
        const ordered = [];
        const push = appId => {
            if (ordered.indexOf(appId) === -1)
                ordered.push(appId);
        };

        // Apps already placed keep their slot, then newly pinned apps in saved
        // order, then apps that just opened a window.
        for (const appId of root.order)
            if (groups.has(appId) || pinnedIds.indexOf(appId) !== -1)
                push(appId);
        for (const appId of pinnedIds)
            push(appId);
        for (const appId of running)
            push(appId);

        root.order = ordered;
        root.items = ordered.map(appId => ({
            appId: appId,
            entry: DesktopEntries.heuristicLookup(appId),
            toplevels: groups.get(appId) ?? [],
            pinned: pinnedIds.indexOf(appId) !== -1
        }));
    }

    Component.onCompleted: root.rebuild()

    Connections {
        target: ToplevelManager.toplevels

        function onValuesChanged() {
            root.rebuild();
        }
    }

    // appId can arrive after the toplevel shows up in the manager.
    Instantiator {
        model: ToplevelManager.toplevels

        delegate: QtObject {
            required property Toplevel modelData
            readonly property string appId: modelData.appId
            onAppIdChanged: root.rebuild()
        }
    }
}
