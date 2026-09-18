import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.Core
import qs.Services
import qs.Modules.Launcher.Providers

Rectangle {
    id: root
    width: parent.width
    // Image entries get a taller row so the thumbnail is actually readable.
    height: root.isImage ? 76 : 40
    color: ListView.isCurrentItem ? Config.colorscheme.accent :
           hoverHandler.hovered ? Config.colorscheme.surface : "transparent"
    radius: Config.island.radius / 2
    required property var modelData
    readonly property bool isImage: modelData.iconType === LauncherProvider.IconType.Preview

    // Previews are decoded lazily, so the delegate asks for the one it needs and
    // picks it up from CliphistService.previews once the decode lands. Delegates are
    // recycled onto new entries without being recreated, hence both handlers.
    function requestPreview() {
        if (root.modelData && root.modelData.previewKey)
            CliphistService.ensureDecoded(root.modelData.previewKey);
    }
    onModelDataChanged: root.requestPreview()
    Component.onCompleted: root.requestPreview()

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            LauncherService.launch(root.modelData)
        }
    }

    Row {
        spacing: 10
        anchors.fill: parent
        anchors.margins: 10

        ClippingRectangle {
            visible: root.isImage
            width: root.isImage ? 96 : 0
            height: parent.height
            radius: Config.island.radius / 2
            color: Config.colorscheme.surface
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: CliphistService.previews[root.modelData.previewKey] ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Bound on both axes so neither a panorama nor a tall screenshot is
                // decoded at full size just to fill a 96px box.
                sourceSize.width: 256
                sourceSize.height: 256
            }
        }

        IconImage {
            visible: (root.modelData.iconType === LauncherProvider.IconType.Application
                    || root.modelData.iconType === undefined)
                    && source.toString().length > 0
            source: {
                const icon = Quickshell.iconPath(root.modelData.icon, true);
                return icon;
            }
            width: parent.height
            height: parent.height
            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            visible: root.modelData.iconType === LauncherProvider.IconType.Material
            text: root.modelData.icon ?? ""
            icon: true
            width: parent.height
            height: parent.height
            font.pixelSize: Config.theme.fontSize * 1.15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            color: root.ListView.isCurrentItem ? Config.colorscheme.bg : Config.colorscheme.fg
        }

        ThemedText {
            visible: root.modelData.iconType === LauncherProvider.IconType.Emoji
            text: root.modelData.icon ?? ""
            width: parent.height
            height: parent.height
            font.pixelSize: Config.theme.fontSize * 1.15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: root.modelData.name ?? ""
            color: root.ListView.isCurrentItem ? Config.colorscheme.bg : Config.colorscheme.fg
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: root.modelData.genericName ?? ""
            color: root.ListView.isCurrentItem ? Config.colorscheme.bg : Config.colorscheme.fg
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.5
        }
    }

    ThemedText {
        text: "arrow-bend-down-left"
        icon: true
        anchors.right: parent.right
        anchors.margins: 10
        anchors.verticalCenter: parent.verticalCenter
        color: Config.colorscheme.bg
        visible: root.ListView.isCurrentItem
        font.pixelSize: Config.theme.fontSize * 1.15
    }
}
