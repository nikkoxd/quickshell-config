import Quickshell
import QtQuick
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

    // Provider the launcher opens on. Set through openView() params, so
    // `ipc call bar launcher <provider>` lands straight in that provider.
    property string initialProvider: "default"

    // Registry of launcher providers. To add a provider: create a file in Providers/
    // extending LauncherProvider and add one instance here.
    DefaultProvider { id: defaultProvider }
    ThemesProvider { id: themesProvider }
    PasswordsProvider { id: passwordsProvider  }
    EmojiProvider { id: emojiProvider }
    ClipboardProvider { id: clipboardProvider }
    ProcessProvider { id: processProvider }

    function launchSelected() {
        if (list.currentItem && list.currentItem.modelData)
            LauncherService.launch(list.currentItem.modelData);
    }

    Component.onCompleted: {
        // Add created providers to the list
        LauncherService.providers = [
            defaultProvider,
            themesProvider,
            passwordsProvider,
            emojiProvider,
            clipboardProvider,
            processProvider
        ];
        LauncherService.reset(root.initialProvider);
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
            list.selectTop();
        }
        function onClearQueryRequested() {
            searchInput.text = "";
            // Providers clear the query when they navigate (the process manager
            // drilling into its action list), so the highlight has to come back to
            // the top with it — the new list has nothing to do with the old one.
            list.selectTop();
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
                borderless: true
                placeholderTextColor: Config.colorscheme.fg
                horizontalPadding: 6
                backgroundImplicitWidth: 400
                backgroundImplicitHeight: 20
                onTextChanged: {
                    LauncherService.query = text;
                    list.selectTop();
                }
                Component.onCompleted: forceActiveFocus()
                // Providers with their own navigation (the process manager drills
                // into actions and signals) get to pop a level first.
                Keys.onEscapePressed: {
                    if (LauncherService.activeProvider()?.goBack())
                        return;
                    root.closeRequested();
                }
                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;

                    if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
                        event.accepted = true;
                        if (list.currentIndex > 0)
                            list.select(list.currentIndex - 1);
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
                        event.accepted = true;
                        if (list.currentIndex < list.count - 1)
                            list.select(list.currentIndex + 1);
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
            // A provider that refreshes itself — the process table re-runs ps every
            // couple of seconds — hands over a brand new array each time, which
            // resets the view and drops the highlight back to the top. Put it back
            // on whatever row it was on, in the same frame: deferring it to the next
            // one is exactly long enough to see the highlight blink to the top.
            onValuesChanged: list.restoreSelection()
        }

        ListView {
            id: list
            clip: true
            // The ScriptModel itself, not its `values` array: handed the bare array
            // the view rebuilds itself on every assignment, which throws the
            // selection away each time a self-refreshing provider ticks. The model
            // diffs instead, so a re-sort is a set of moves and the highlight rides
            // along with its row.
            model: filtered

            // Identity of the highlighted entry, so the selection survives the model
            // being replaced wholesale. Empty means "whatever is on top".
            property string selectionKey: ""

            // The list is taller than its 300px window, so moving the highlight has
            // to bring it along — otherwise a selection made off-screen (or one
            // carried over from a longer list) leaves no visible highlight at all.
            function select(index) {
                list.currentIndex = index;
                list.selectionKey = LauncherService.entryKey(filtered.values[index]);
                list.positionViewAtIndex(index, ListView.Contain);
            }

            function selectTop() {
                list.selectionKey = "";
                list.currentIndex = 0;
                list.positionViewAtIndex(0, ListView.Contain);
            }

            function restoreSelection() {
                const values = filtered.values ?? [];
                if (values.length === 0)
                    return;

                // No key means the highlight is parked on the first row, and it has
                // to stay there: the model inserts rather than resets now, so rows
                // arriving above it (a provider whose entries load in) would
                // otherwise carry it down the list.
                if (!list.selectionKey) {
                    list.currentIndex = 0;
                    list.positionViewAtIndex(0, ListView.Contain);
                    return;
                }

                for (let i = 0; i < values.length; i++) {
                    if (LauncherService.entryKey(values[i]) === list.selectionKey) {
                        list.currentIndex = i;
                        list.positionViewAtIndex(i, ListView.Contain);
                        return;
                    }
                }

                // The entry is gone (a killed process, a dropped clipboard item):
                // hold the position in the list rather than jumping to the top.
                list.select(Math.min(list.currentIndex, values.length - 1));
            }
            width: parent.width
            height: Math.min(contentHeight, 300)
            spacing: 5
            delegate: LauncherEntry {}
        }
    }
}
