pragma Singleton
import Quickshell
import QtQuick
import QtMultimedia
import Qt.labs.folderlistmodel
import qs.Core

Singleton {
    id: root

    // File names (with extension) of everything dropped into Sounds/, in the
    // order the pickers offer them.
    property var names: []

    function _rebuild() {
        const list = [];

        for (let i = 0; i < soundFiles.count; i++) {
            const name = String(soundFiles.get(i, "fileName"));
            if (name) {
                list.push(name);
            }
        }

        list.sort();
        root.names = list;
    }

    // The configured name if Sounds/ still holds it, otherwise the first sound
    // there: a config naming a file the user has since deleted should fall back
    // to something audible rather than go silent without saying so.
    function resolve(name) {
        if (name && root.names.includes(name))
            return name;
        return root.names.length > 0 ? root.names[0] : "";
    }

    function pathOf(name) {
        return name ? Qt.resolvedUrl("../Sounds/" + name) : "";
    }

    // `volume` is a percentage, matching how the config stores it.
    function play(name, volume) {
        const file = root.resolve(name);
        if (!file)
            return;

        player.stop();
        output.volume = Math.max(0, Math.min(1, (volume !== undefined ? volume : 100) / 100));
        player.source = root.pathOf(file);
        player.play();
    }

    function playNotification() {
        if (!Config.notifications.sound)
            return;
        root.play(Config.notifications.soundFile, Config.notifications.soundVolume);
    }

    function _toUrl(path) {
        if (path.indexOf("://") !== -1)
            return path;
        return path.startsWith("/") ? "file://" + path : Qt.resolvedUrl(path);
    }

    function playPath(path, volume) {
        if (!path)
            return;

        player.stop();
        output.volume = Math.max(0, Math.min(1, (volume !== undefined ? volume : 100) / 100));
        player.source = root._toUrl(path);
        player.play();
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput {
            id: output
        }
    }

    FolderListModel {
        id: soundFiles
        folder: Qt.resolvedUrl("../Sounds")
        nameFilters: ["*.mp3", "*.ogg", "*.wav", "*.flac", "*.opus", "*.m4a"]
        showDirs: false
        showDotAndDotDot: false
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                root._rebuild();
            }
        }
        onCountChanged: root._rebuild()
    }
}
