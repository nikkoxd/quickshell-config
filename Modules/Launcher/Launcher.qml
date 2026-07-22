import Quickshell
import QtQuick
import QtQuick.Controls
import qs.Core
import qs.Services
import qs.Modules.Launcher.Providers

View {
    id: root
    implicitWidth: column.implicitWidth + 20
    implicitHeight: column.implicitHeight + 20
    dismissable: false
    focused: true
    displayInFullscreen: true

    // Registry of launcher providers. To add a provider: create a file in Providers/
    // extending LauncherProvider and add one instance here.
    DefaultProvider { id: defaultProvider; svc: LauncherService }
    ThemesProvider { id: themesProvider; svc: LauncherService }
    PasswordsProvider { id: passwordsProvider; svc: LauncherService  }
    EmojiProvider { id: emojiProvider; svc: LauncherService }

    function launchSelected() {
        if (list.currentItem && list.currentItem.modelData)
            LauncherService.launch(list.currentItem.modelData);
    }

    Component.onCompleted: {
        // Add created providers to the list
        LauncherService.providers = [defaultProvider, themesProvider, passwordsProvider, emojiProvider];
        LauncherService.reset();
        searchInput.forceActiveFocus();
    }

    Connections {
        target: LauncherService
        function onCloseRequested() {
            root.closeRequested();
        }
        function onViewChangeRequested(view) {
            root.viewChangeRequested(view);
        }
        function onProviderChanged() {
            searchInput.text = "";
        }
        function onClearQueryRequested() {
            searchInput.text = "";
        }
    }

    Column {
        id: column
        spacing: 10
        y: 10
        anchors.horizontalCenter: parent.horizontalCenter

        Row {
            spacing: 2

            ThemedText {
                id: icon
                text: LauncherService.activeProvider()?.headerIcon ?? "search"
                icon: true
                font.pixelSize: Config.theme.fontSize * 1.15
                anchors.verticalCenter: parent.verticalCenter

                onTextChanged: iconAnim.restart()

                SequentialAnimation {
                    id: iconAnim
                    NumberAnimation {
                        target: icon
                        property: "scale"
                        from: 1
                        to: 0
                        duration: 0
                    }
                    NumberAnimation {
                        target: icon
                        property: "scale"
                        from: 0
                        to: 1
                        duration: 350
                        easing.type: Easing.InOutQuart
                    }
                }
            }

            TextField {
                id: searchInput
                focus: true
                activeFocusOnTab: true
                placeholderText: LauncherService.activeProvider()?.placeholder ?? "Search..."
                echoMode: LauncherService.activeProvider()?.hideQuery ? TextInput.Password : TextInput.Normal
                color: Config.colorscheme.fg
                placeholderTextColor: Config.colorscheme.fg
                selectionColor: Config.colorscheme.accent
                selectedTextColor: Config.colorscheme.bg
                font.family: Config.theme.fontFamily
                font.pixelSize: Config.theme.fontSize
                background: Item {
                    implicitWidth: 400
                    implicitHeight: 20
                }
                onTextChanged: LauncherService.query = text
                Component.onCompleted: forceActiveFocus()
                Keys.onEscapePressed: root.closeRequested()
                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;

                    if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
                        event.accepted = true;
                        if (list.currentIndex > 0)
                            list.currentIndex--;
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
                        event.accepted = true;
                        if (list.currentIndex < list.count - 1)
                            list.currentIndex++;
                    } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                        event.accepted = true;
                        root.launchSelected();
                    }
                }
            }
        }

        ScriptModel {
            id: filtered
            values: LauncherService.results()
        }

        ListView {
            id: list
            clip: true
            model: filtered.values
            width: parent.width
            height: Math.min(contentHeight, 200)
            spacing: 5
            delegate: LauncherEntry {}
        }
    }
}
