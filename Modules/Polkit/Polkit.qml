pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

// The polkit password prompt. Bar.qml opens it over whatever is on screen when
// PolkitService.requested fires: the program asking is blocked until this is
// answered, so it must not wait behind an interactive view.
//
// Closing the view any way other than a finished flow (Escape, clicking
// outside, another view replacing it) cancels the request, so the caller gets
// a clean "not authorized" instead of hanging.
View {
    id: root

    readonly property real padding: 15
    readonly property AuthFlow flow: PolkitService.flow

    implicitWidth: layout.width + root.padding * 2
    implicitHeight: {
        const base = layout.implicitHeight + root.padding * 2;
        if (!identityPicker.expanded)
            return base;
        return Math.max(base, root.padding + identityPicker.y + identityPicker.height + identityPicker.listHeight);
    }

    focused: true
    dismissable: false
    displayInFullscreen: true

    readonly property bool busy: root.flow !== null && !root.flow.isResponseRequired && !root.flow.isCompleted

    readonly property var identityOptions: (root.flow?.identities ?? []).map(identity => ({
                label: identity.displayName || identity.name,
                value: root.identityKey(identity)
            }))

    function identityKey(identity) {
        if (!identity)
            return "";
        return (identity.isGroup ? "group:" : "user:") + identity.name;
    }

    // Deferred, because a finished flow and the next queued one are two
    // separate changes: the prompt stays up if another request is already
    // waiting to be answered.
    function settle() {
        const flow = PolkitService.flow;
        if (flow === null || flow.isCompleted) {
            root.closeRequested();
            return;
        }
        password.text = "";
        password.forceActiveFocus();
    }

    onFlowChanged: Qt.callLater(root.settle)

    Connections {
        target: root.flow

        function onIsCompletedChanged() {
            Qt.callLater(root.settle);
        }

        function onAuthenticationFailed() {
            password.text = "";
            shake.restart();
        }

        function onIsResponseRequiredChanged() {
            if (root.flow.isResponseRequired)
                password.forceActiveFocus();
        }
    }

    Component.onDestruction: {
        if (root.flow !== null && !root.flow.isCompleted)
            root.flow.cancelAuthenticationRequest();
    }

    function submit() {
        if (root.flow === null || !root.flow.isResponseRequired)
            return;
        root.flow.submit(password.text);
    }

    ColumnLayout {
        id: layout
        width: 360
        anchors.centerIn: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                implicitWidth: 32
                implicitHeight: 32
                Layout.alignment: Qt.AlignTop

                readonly property string themedIcon: root.flow?.iconName ? Quickshell.iconPath(root.flow.iconName, true) : ""

                IconImage {
                    anchors.fill: parent
                    source: parent.themedIcon
                    visible: parent.themedIcon !== ""
                }

                ThemedText {
                    anchors.centerIn: parent
                    icon: true
                    text: "lock-key"
                    font.pixelSize: 26
                    visible: parent.themedIcon === ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                ThemedText {
                    Layout.fillWidth: true
                    text: "Authentication required"
                    isHeading: true
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: root.flow?.message ?? ""
                    wrapMode: Text.Wrap
                    opacity: 0.6
                    font.pixelSize: Config.theme.fontSize * 0.9
                }
            }
        }

        Dropdown {
            id: identityPicker
            Layout.fillWidth: true
            visible: root.identityOptions.length > 1
            enabled: !root.busy
            options: root.identityOptions
            current: root.identityKey(root.flow?.selectedIdentity)
            onSelected: value => {
                const identity = root.flow.identities.find(candidate => root.identityKey(candidate) === value);
                if (identity)
                    root.flow.selectedIdentity = identity;
                password.forceActiveFocus();
            }
        }

        RowLayout {
            id: inputRow
            Layout.fillWidth: true
            spacing: 5

            TextField {
                id: password
                Layout.fillWidth: true
                focus: true
                enabled: root.flow?.isResponseRequired ?? false
                opacity: enabled ? 1 : 0.5
                echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                placeholderText: (root.flow?.inputPrompt ?? "").replace(/[:\s]+$/, "") || "Password"
                onAccepted: root.submit()

                Component.onCompleted: forceActiveFocus()
            }

            IconButton {
                implicitWidth: 40
                implicitHeight: 40
                icon: "x-circle"
                onClicked: root.flow?.cancelAuthenticationRequest()
            }

            IconButton {
                implicitWidth: 40
                implicitHeight: 40
                icon: root.busy ? "circle-notch" : "arrow-right"
                active: password.text.length > 0 && !root.busy
                onClicked: root.submit()
            }

            transform: Translate {
                id: shakeOffset
            }

            SequentialAnimation {
                id: shake
                readonly property real distance: 8

                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: shake.distance
                    duration: 50
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: -shake.distance
                    duration: 80
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: shake.distance / 2
                    duration: 70
                }
                NumberAnimation {
                    target: shakeOffset
                    property: "x"
                    to: 0
                    duration: 60
                }
            }
        }

        ThemedText {
            Layout.fillWidth: true
            readonly property string failure: root.flow?.failed ? "Authentication failed, try again" : ""
            text: root.flow?.supplementaryMessage || failure
            visible: text !== ""
            wrapMode: Text.Wrap
            color: root.flow?.supplementaryIsError || root.flow?.failed ? Config.colorscheme.accent : Config.colorscheme.fg
            opacity: 0.8
            font.pixelSize: Config.theme.fontSize * 0.85
        }
    }
}
