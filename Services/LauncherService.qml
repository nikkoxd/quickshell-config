pragma Singleton

import Quickshell

Singleton {
    id: root

    property string query: ""
    property string provider: "default"
    property var mpris: MprisService

    signal viewChangeRequested(string view)
    signal closeRequested()

    function fuzzyScore(query, str) {
        if (!query)
            return 1;
        if (!str)
            return 0;

        const q = query.toLowerCase();
        const s = str.toLowerCase();
        let score = 0;
        let qIdx = 0;
        let lastMatch = -1;

        for (let i = 0; i < s.length && qIdx < q.length; i++) {
            if (s[i] === q[qIdx]) {
                // Bonus for consecutive matches
                if (lastMatch === i - 1)
                    score += 2;
                // Bonus for matching at word boundaries
                if (i === 0 || s[i - 1] === ' ' || s[i - 1] === '-')
                    score += 3;
                lastMatch = i;
                qIdx++;
            }
        }

        // Return 0 if not all characters matched
        if (qIdx < q.length)
            return 0;

        // Penalize length difference (prefer shorter matches)
        return score / s.length;
    }

    function evalMath(expr) {
        // Strip spaces and convert ^ to ** for exponentiation
        const clean = expr.replace(/\s+/g, '').replace(/\^/g, '**');
        // Only allow digits and math operators
        if (!/^[\d+\-*/().]+$/.test(clean))
            return null;
        // Require at least one operator so plain numbers (e.g. "1password") don't trigger
        if (!/[+\-*/()]/.test(clean))
            return null;
        try {
            const result = eval(clean);
            if (typeof result === 'number' && isFinite(result)) {
                return result;
            }
        } catch (e) {}
        return null;
    }

    // Providers are registered by the Launcher view (Modules/Launcher/Launcher.qml).
    // They live in qs.Modules.Launcher.Providers and depend on qs.Core (Config), which
    // itself imports qs.Services — so the service can't import them without a module
    // cycle. Registering from the view keeps the dependency one-directional.
    property var providers: []

    function activeProvider() {
        if (!providers || providers.length === 0)
            return null;
        return providers.find(p => p.providerId === root.provider) ?? providers[0];
    }

    function results() {
        const p = activeProvider();
        return p ? p.entries(root.query) : [];
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        if (entry.preventClose !== true)
            root.closeRequested();
    }

    function reset() {
        root.provider = "default";
        root.query = "";
    }
}
