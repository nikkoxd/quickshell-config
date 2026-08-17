pragma Singleton

import Quickshell

Singleton {
    id: root

    property string query: ""
    property string provider: "default"
    property var mpris: MprisService

    signal viewChangeRequested(string view)
    signal settingsRequested()
    signal closeRequested()
    signal clearQueryRequested()

    function fuzzyScore(query, str) {
        if (!query)
            return 1;
        if (!str)
            return 0;

        /* const q = query.toLowerCase(); */
        /* const s = str.toLowerCase(); */
        let score = 0;
        let qIdx = 0;
        let lastMatch = -1;

        for (let i = 0; i < str.length && qIdx < query.length; i++) {
            let sCode = str.charCodeAt(i);
            let qCode = query.charCodeAt(qIdx);
            if (sCode === qCode ||
                (sCode >= 64 && sCode <= 90 && sCode + 32 === qCode) ||
                (sCode >= 97 && sCode <= 122 && sCode - 32 === qCode)) {
                // Bonus for consecutive matches
                if (lastMatch === i - 1)
                    score += 2;
                // Bonus for matching at word boundaries
                if (i === 0 || str[i - 1] === ' ' || str[i - 1] === '-')
                    score += 3;
                lastMatch = i;
                qIdx++;
            }
        }

        // Return 0 if not all characters matched
        if (qIdx < query.length)
            return 0;

        // Penalize length difference (prefer shorter matches)
        return score / str.length;
    }

    // Score `entries` against `query` on the given `keys` (default ["name"]),
    // keeping matches sorted best-first. Reuses fuzzyScore per key, then scales by
    // the entry's usage frecency (1x when unused), so an empty query — where every
    // text score is 1 — ends up ordered purely by usage.
    function fuzzyFilter(query, entries, keys) {
        keys = keys ?? ["name"];
        return entries.map((entry, index) => {
            let score = 0;
            for (const key of keys)
                if (entry[key])
                    score = Math.max(score, fuzzyScore(query, entry[key]));
            return { entry, index, score: score * usageBoost(entry) };
        }).filter(item => item.score > 0)
          .sort((a, b) => b.score - a.score || a.index - b.index)
          .map(item => item.entry);
    }

    // Usage frecency multiplier for an entry, scoped to the active provider.
    // 1 for never-launched entries, so a zero text score stays zero.
    function usageBoost(entry) {
        return LauncherUsageService.boost(LauncherUsageService.key(entry, root.provider));
    }

    // Substring-match `entries` against `query` on their `search` field, ranked
    // by match position (earlier ranks higher) and usage frecency, then by shorter
    // `name` on ties. Returns at most `maxResults` entries; the most-used entries
    // (sliced) when no query.
    function substringFilter(query, entries, maxResults) {
        if (!query) {
            return entries.map((entry, index) => ({ entry, index, score: usageBoost(entry) }))
                .sort((a, b) => b.score - a.score || a.index - b.index)
                .slice(0, maxResults)
                .map(item => item.entry);
        }

        const q = query.toLowerCase();
        const matches = [];
        for (let i = 0; i < entries.length; i++) {
            const idx = entries[i].search.indexOf(q);
            if (idx !== -1)
                matches.push({ entry: entries[i], index: i, score: usageBoost(entries[i]) / (1 + idx) });
        }
        matches.sort((a, b) => b.score - a.score
                            || a.entry.name.length - b.entry.name.length
                            || a.index - b.index);

        const out = [];
        for (let i = 0; i < matches.length && i < maxResults; i++)
            out.push(matches[i].entry);
        return out;
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
        LauncherUsageService.record(LauncherUsageService.key(entry, root.provider));
        entry.execute();
        if (entry.preventClose !== true)
            root.closeRequested();
    }

    function reset() {
        root.provider = "default";
        root.query = "";
    }
}
