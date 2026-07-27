import QtQuick
import QtMultimedia
import qs.Core
import qs.Services

Item {
    id: root

    property url wallpaper: Config.wallpaper.current
    property int wallpaperType: WallpaperService.toType(Config.wallpaper.type)

    Connections {
        target: WallpaperService
        function onWallpaperChanged(path, type) {
            root.wallpaper = path;
            root.wallpaperType = type;
        }
    }

    Loader {
        id: wallpaperLoader
        anchors.fill: parent
        sourceComponent: root.wallpaperType === WallpaperService.Type.Mpvpaper ? videoComp : imageComp
    }

    Component {
        id: imageComp
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.wallpaper
        }
    }

    Component {
        id: videoComp
        VideoOutput {
            id: vo
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            MediaPlayer {
                id: player
                source: root.wallpaper
                videoOutput: vo
                loops: MediaPlayer.Infinite
                audioOutput: null

                // play() is a no-op until the media is loaded (FFmpeg
                // backend), so drive playback off mediaStatus rather than
                // Component.onCompleted.
                onMediaStatusChanged: {
                    if (mediaStatus >= MediaPlayer.LoadedMedia)
                        play();
                }
                onErrorOccurred: (err, str) => console.log("[lockscreen video] error", err, str)
            }
        }
    }
}
