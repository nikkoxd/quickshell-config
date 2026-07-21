import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.Core
import qs.Modules.Launcher.Providers

Rectangle {
    id: root
    width: parent.width
    height: 40
    color: ListView.isCurrentItem ? Config.colorscheme.accent : "transparent"
    radius: Config.island.radius / 2
    required property var modelData

    Row {
        spacing: 10
        anchors.fill: parent
        anchors.margins: 10

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
            text: root.modelData.icon
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
            text: root.modelData.name
            color: root.ListView.isCurrentItem ? Config.colorscheme.bg : Config.colorscheme.fg
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedText {
            text: root.modelData.genericName
            color: root.ListView.isCurrentItem ? Config.colorscheme.bg : Config.colorscheme.fg
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.5
        }
    }

    ThemedText {
        text: "keyboard_return"
        icon: true
        anchors.right: parent.right
        anchors.margins: 10
        anchors.verticalCenter: parent.verticalCenter
        color: Config.colorscheme.bg
        visible: root.ListView.isCurrentItem
        font.pixelSize: Config.theme.fontSize * 1.15
    }
}
