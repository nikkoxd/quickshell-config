import QtQuick
import qs.Core
import qs.Services

// "artist - track", shown in the default view's centre for a moment after the
// song changes or playback resumes. This used to be the Player view, which
// replaced the whole island - and every indicator around it - to say the same
// thing; as one of the centres it swaps with the clock alone.
ScrollingText {
    id: root

    // ScrollingText sizes itself with `width`/`height`, but the centre stacks
    // its alternatives by implicit size, so mirror the two.
    implicitWidth: root.width
    implicitHeight: root.height

    maxWidth: 260

    readonly property var player: MprisService.activePlayer

    text: {
        if (!root.player)
            return "";
        const artist = root.player.trackArtist || "";
        const title = root.player.trackTitle || "";
        if (artist.length === 0)
            return title;
        if (title.length === 0)
            return artist;
        return artist + " - " + title;
    }
}
