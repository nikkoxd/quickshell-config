pragma ComponentBehavior: Bound
import Quickshell.Widgets
import QtQuick
import qs.Core

// A search result blown up before it is downloaded: the full image, fitted to
// the stage and zoomable towards the cursor (wheel, +/-, or a double click for
// actual pixels), dragged around once it overflows. The larger thumbnail
// stands in while the full image is still coming off the network. Its tags
// run along the bottom, each one a search of its own.
FocusScope {
    id: root

    // One results row: { wallpaperId, url, preview, resolution, fileSize }.
    property var wallpaper: ({})
    property bool downloading: false
    property bool downloaded: false
    // { id, name, category, purity } each; looked up separately, since search
    // results do not carry them.
    property var tags: []
    property bool tagsLoading: false
    property string tagsError: ""

    signal downloadRequested
    signal closeRequested
    signal tagClicked(string name)

    readonly property real minZoom: 1
    readonly property real maxZoom: Math.max(8, root.actualZoom * 2)

    // The wallpaper's own size, known from the search result before any of it
    // has loaded, so the stage can be laid out for it straight away.
    readonly property var imageSize: {
        const parts = (root.wallpaper.resolution || "").split("x").map(Number);
        return parts.length === 2 && parts[0] > 0 && parts[1] > 0 ? Qt.size(parts[0], parts[1]) : Qt.size(16, 9);
    }

    // The image fitted into the stage, which is zoom 1.
    readonly property real fitWidth: Math.min(flick.width, flick.height * root.imageSize.width / root.imageSize.height)
    readonly property real fitHeight: root.fitWidth * root.imageSize.height / root.imageSize.width
    // The zoom at which one image pixel is one screen pixel.
    readonly property real actualZoom: root.fitWidth > 0 ? root.imageSize.width / root.fitWidth : 1

    property real zoom: 1

    // Zoom to `target`, keeping the image point under `point` (in stage
    // coordinates) where it is.
    function zoomTo(target, point) {
        const next = Math.max(root.minZoom, Math.min(root.maxZoom, target));
        if (next === root.zoom)
            return;

        const ratio = next / root.zoom;
        const imageX = flick.contentX + point.x - canvas.x;
        const imageY = flick.contentY + point.y - canvas.y;

        root.zoom = next;

        flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, imageX * ratio + canvas.x - point.x));
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, imageY * ratio + canvas.y - point.y));
    }

    function zoomBy(factor) {
        root.zoomTo(root.zoom * factor, Qt.point(flick.width / 2, flick.height / 2));
    }

    function formatSize(bytes) {
        if (bytes <= 0)
            return "";
        if (bytes < 1024 * 1024)
            return Math.round(bytes / 1024) + " KB";
        return (bytes / 1024 / 1024).toFixed(1) + " MB";
    }

    focus: true
    Keys.onEscapePressed: root.closeRequested()
    Keys.onReturnPressed: root.downloadRequested()
    Keys.onEnterPressed: root.downloadRequested()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            root.zoomBy(1.25);
        } else if (event.key === Qt.Key_Minus) {
            root.zoomBy(0.8);
        } else if (event.key === Qt.Key_0) {
            root.zoomTo(1, Qt.point(flick.width / 2, flick.height / 2));
        } else {
            return;
        }
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Config.colorscheme.bg
    }

    // The browser is still underneath; nothing that misses the stage and the
    // toolbar should reach it.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    ClippingRectangle {
        id: stage
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: tagRow.top
        anchors.bottomMargin: 10
        radius: 8
        color: Config.colorscheme.surface

        Flickable {
            id: flick
            anchors.fill: parent
            contentWidth: Math.max(width, canvas.width)
            contentHeight: Math.max(height, canvas.height)
            boundsBehavior: Flickable.StopAtBounds
            // Only something to pan once it overflows; at fit a drag would do
            // nothing but fight the double click.
            interactive: root.zoom > 1

            Item {
                id: canvas
                width: root.fitWidth * root.zoom
                height: root.fitHeight * root.zoom
                // Centred on whichever axis still fits the stage.
                x: Math.max(0, (flick.width - width) / 2)
                y: Math.max(0, (flick.height - height) / 2)

                Image {
                    id: placeholder
                    anchors.fill: parent
                    source: root.wallpaper.preview || ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: full.status !== Image.Ready
                }

                Image {
                    id: full
                    anchors.fill: parent
                    source: root.wallpaper.url || ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    // Decoded at full resolution for the zoom; one of these is
                    // plenty, so it is not kept around after the preview goes.
                    cache: false
                    smooth: true
                    mipmap: true
                }
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const steps = event.angleDelta.y / 120;
                    if (steps !== 0) {
                        root.zoomTo(root.zoom * Math.pow(1.2, steps), Qt.point(event.x, event.y));
                    }
                }
            }

            // Double click flips between fitted and actual pixels, around the
            // point clicked.
            TapHandler {
                onDoubleTapped: eventPoint => root.zoomTo(root.zoom > 1 ? 1 : Math.max(root.actualZoom, 2), eventPoint.position)
            }

            HoverHandler {
                cursorShape: root.zoom > 1 ? (flick.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            width: loadingLabel.implicitWidth + 16
            height: loadingLabel.implicitHeight + 8
            radius: height / 2
            color: Qt.alpha(Config.colorscheme.bg, 0.75)
            visible: full.status === Image.Loading || full.status === Image.Error

            ThemedText {
                id: loadingLabel
                anchors.centerIn: parent
                text: full.status === Image.Error ? "Could not load the full image" : "Loading full image… " + Math.round(full.progress * 100) + "%"
                font.pixelSize: Config.theme.fontSize * 0.85
            }
        }
    }

    Item {
        id: tagRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: toolbar.top
        anchors.bottomMargin: 8
        height: 30

        // One line, scrolled sideways, however many tags there are, so the
        // stage keeps its height from one wallpaper to the next.
        ListView {
            id: tagList
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.tags

            delegate: Chip {
                required property var modelData
                anchors.verticalCenter: parent?.verticalCenter
                horizontalPadding: 12
                verticalPadding: 4
                text: modelData.name
                onClicked: root.tagClicked(modelData.name)
            }
        }

        ThemedText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: tagList.count === 0
            text: root.tagsLoading ? "Loading tags…" : root.tagsError || "No tags"
            color: Qt.alpha(Config.colorscheme.fg, 0.6)
            font.pixelSize: Config.theme.fontSize * 0.9
        }
    }

    Item {
        id: toolbar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 32

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: [root.wallpaper.resolution, root.formatSize(root.wallpaper.fileSize || 0)].filter(part => part).join("  ·  ")
                color: Qt.alpha(Config.colorscheme.fg, 0.6)
                font.pixelSize: Config.theme.fontSize * 0.9
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                // Relative to actual pixels, which is what a zoom level means
                // to anyone judging whether a wallpaper is sharp enough.
                text: Math.round(root.zoom / root.actualZoom * 100) + "%"
                color: Qt.alpha(Config.colorscheme.fg, 0.6)
                font.pixelSize: Config.theme.fontSize * 0.9
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            IconButton {
                icon: "magnifying-glass-minus"
                onClicked: root.zoomBy(0.8)
            }

            IconButton {
                icon: "magnifying-glass-plus"
                onClicked: root.zoomBy(1.25)
            }

            Chip {
                anchors.verticalCenter: parent.verticalCenter
                active: true
                text: root.downloading ? "Downloading…" : root.downloaded ? "Apply" : "Download and apply"
                onClicked: root.downloadRequested()
            }

            IconButton {
                icon: "arrow-u-up-left"
                onClicked: root.closeRequested()
            }
        }
    }
}
