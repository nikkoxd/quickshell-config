pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

// Countdown timer. Fully keyboard driven: Tab/Shift+Tab (or the arrow keys)
// move between the hour, minute and second slots, digits are typed in
// phone-dial fashion (shifted in from the right), Enter starts, Space
// pauses/resumes, R repeats the last timer, S stops and Escape closes.
//
// While a timer is running the slots show its remaining time instead of the
// edited value, so the same three numbers serve as both the input and the
// readout. Typing then stops the timer and goes back to editing.
View {
    id: root
    implicitWidth: layout.implicitWidth + 30
    implicitHeight: layout.implicitHeight + 30
    focused: true
    dismissable: false
    displayInFullscreen: true

    // Slot indices. Plain constants rather than an enum: the file is named
    // Timer.qml, so a self-reference (Timer.Field.Hours) would read as
    // QtQuick's Timer type here.
    readonly property int fieldHours: 0
    readonly property int fieldMinutes: 1
    readonly property int fieldSeconds: 2

    property int field: root.fieldHours

    // The value being edited, only meaningful while no timer is set.
    property int editHours: 0
    property int editMinutes: 0
    property int editSeconds: 0

    function slotValue(field) {
        if (TimerService.active) {
            if (field === root.fieldHours)
                return TimerService.hours;
            if (field === root.fieldMinutes)
                return TimerService.minutes;
            return TimerService.seconds;
        }
        if (field === root.fieldHours)
            return root.editHours;
        if (field === root.fieldMinutes)
            return root.editMinutes;
        return root.editSeconds;
    }

    function setSlot(field, value) {
        const max = field === root.fieldHours ? 99 : 59;
        const clamped = Math.max(0, Math.min(max, value));
        if (field === root.fieldHours)
            root.editHours = clamped;
        else if (field === root.fieldMinutes)
            root.editMinutes = clamped;
        else
            root.editSeconds = clamped;
    }

    // Editing takes the running timer's remaining time as the starting point,
    // so typing over a countdown adjusts it instead of wiping it to zero.
    function beginEdit() {
        if (!TimerService.active)
            return;
        root.editHours = TimerService.hours;
        root.editMinutes = TimerService.minutes;
        root.editSeconds = TimerService.seconds;
        TimerService.stop();
    }

    function typeDigit(digit) {
        root.beginEdit();
        const shifted = (root.slotValue(root.field) % 10) * 10 + digit;
        // 59 -> type 7 -> 97 is out of range for minutes/seconds; the digit
        // typed last is what the user meant, so keep that alone.
        const max = root.field === root.fieldHours ? 99 : 59;
        root.setSlot(root.field, shifted > max ? digit : shifted);
    }

    function step(delta) {
        root.beginEdit();
        root.setSlot(root.field, root.slotValue(root.field) + delta);
    }

    function backspace() {
        root.beginEdit();
        root.setSlot(root.field, Math.floor(root.slotValue(root.field) / 10));
    }

    function moveField(delta) {
        root.field = (root.field + delta + 3) % 3;
    }

    function startOrResume() {
        if (TimerService.running)
            return;
        if (TimerService.paused) {
            TimerService.resume();
            return;
        }
        TimerService.startParts(root.editHours, root.editMinutes, root.editSeconds);
    }

    component Slot: Rectangle {
        id: slot

        required property int field
        required property string label

        readonly property bool current: root.field === slot.field

        implicitWidth: 76
        implicitHeight: 76
        radius: Config.island.radius / 2
        color: slot.current ? Config.colorscheme.accent : Config.colorscheme.surface

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuart
            }
        }

        TapHandler {
            onTapped: root.field = slot.field
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        Column {
            anchors.centerIn: parent
            spacing: 0

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const value = root.slotValue(slot.field);
                    return value < 10 ? "0" + value : "" + value;
                }
                color: slot.current ? Config.colorscheme.bg : Config.colorscheme.fg
                font.pixelSize: Config.theme.fontSize * 2.2
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: slot.label
                color: slot.current ? Config.colorscheme.bg : Config.colorscheme.fg
                opacity: 0.6
                font.pixelSize: Config.theme.fontSize * 0.8
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        ViewHeader {
            Layout.fillWidth: true
            text: TimerService.paused ? "Timer (paused)" : "Timer"

            IconButton {
                icon: "play"
                activeIcon: "pause"
                active: TimerService.running
                onClicked: {
                    if (TimerService.running)
                        TimerService.pause();
                    else
                        root.startOrResume();
                }
            }

            IconButton {
                icon: "stop"
                onClicked: TimerService.stop()
            }

            IconButton {
                icon: "arrow-counter-clockwise"
                onClicked: TimerService.repeat()
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Slot {
                field: root.fieldHours
                label: "hours"
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: ":"
                font.pixelSize: Config.theme.fontSize * 1.6
                opacity: 0.5
            }

            Slot {
                field: root.fieldMinutes
                label: "min"
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: ":"
                font.pixelSize: Config.theme.fontSize * 1.6
                opacity: 0.5
            }

            Slot {
                field: root.fieldSeconds
                label: "sec"
            }
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            opacity: 0.5
            font.pixelSize: Config.theme.fontSize * 0.85
            text: {
                if (TimerService.running)
                    return "Space pause · S stop · R repeat";
                if (TimerService.paused)
                    return "Enter resume · S stop · R repeat";
                if (TimerService.lastDuration > 0)
                    return "Tab switch · Enter start · R repeat";
                return "Tab switch · digits set · Enter start";
            }
        }
    }

    // The key handling lives on a focused child so the view's own Escape
    // shortcut and this handler don't fight over the same item.
    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Component.onCompleted: keys.forceActiveFocus()

        Keys.onPressed: event => {
            const shift = event.modifiers & Qt.ShiftModifier;

            if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                event.accepted = true;
                root.typeDigit(event.key - Qt.Key_0);
                return;
            }

            switch (event.key) {
            case Qt.Key_Tab:
                event.accepted = true;
                // Some layouts report Shift+Tab as Key_Tab with the modifier.
                root.moveField(shift ? -1 : 1);
                break;
            case Qt.Key_Backtab:
                event.accepted = true;
                root.moveField(-1);
                break;
            case Qt.Key_Right:
                event.accepted = true;
                root.moveField(1);
                break;
            case Qt.Key_Left:
                event.accepted = true;
                root.moveField(-1);
                break;
            case Qt.Key_Up:
                event.accepted = true;
                root.step(1);
                break;
            case Qt.Key_Down:
                event.accepted = true;
                root.step(-1);
                break;
            case Qt.Key_Backspace:
            case Qt.Key_Delete:
                event.accepted = true;
                root.backspace();
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                event.accepted = true;
                root.startOrResume();
                break;
            case Qt.Key_Space:
                event.accepted = true;
                TimerService.toggle();
                break;
            case Qt.Key_R:
                event.accepted = true;
                TimerService.repeat();
                break;
            case Qt.Key_S:
                event.accepted = true;
                TimerService.stop();
                break;
            }
        }
    }
}
