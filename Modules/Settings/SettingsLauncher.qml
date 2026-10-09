import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    SettingsOption {
        title: "Show results with empty query"
        value: SettingsDraft.get("launcher", "showResultsWithEmptyQuery")
        onChecked: value => SettingsDraft.set("launcher", "showResultsWithEmptyQuery", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Sort results by usage"
        value: SettingsDraft.get("launcher", "sortByUsage")
        onChecked: value => SettingsDraft.set("launcher", "sortByUsage", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Custom entries behind prefix"
        value: SettingsDraft.get("launcher", "useCustomEntriesPrefix")
        onChecked: value => SettingsDraft.set("launcher", "useCustomEntriesPrefix", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Custom entries prefix"
        visible: SettingsDraft.get("launcher", "useCustomEntriesPrefix")
        value: SettingsDraft.get("launcher", "customEntriesPrefix")
        onEdited: value => SettingsDraft.set("launcher", "customEntriesPrefix", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Run command prefix"
        value: SettingsDraft.get("launcher", "commandPrefix")
        onEdited: value => SettingsDraft.set("launcher", "commandPrefix", value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Process sort"
        value: SettingsDraft.get("launcher", "processSort")
        options: [
            { label: "CPU", value: "cpu" },
            { label: "Memory", value: "memory" },
            { label: "Name", value: "name" },
            { label: "PID", value: "pid" }
        ]
        onEdited: value => SettingsDraft.set("launcher", "processSort", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Group processes by name"
        value: SettingsDraft.get("launcher", "groupProcesses")
        onChecked: value => SettingsDraft.set("launcher", "groupProcesses", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Show system processes"
        value: SettingsDraft.get("launcher", "showSystemProcesses")
        onChecked: value => SettingsDraft.set("launcher", "showSystemProcesses", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Service sort"
        value: SettingsDraft.get("launcher", "systemdSort")
        options: [
            { label: "State", value: "state" },
            { label: "Name", value: "name" }
        ]
        onEdited: value => SettingsDraft.set("launcher", "systemdSort", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Services from"
        value: SettingsDraft.get("launcher", "systemdScope")
        options: [
            { label: "User and system", value: "both" },
            { label: "User", value: "user" },
            { label: "System", value: "system" }
        ]
        onEdited: value => SettingsDraft.set("launcher", "systemdScope", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Show only .service units"
        value: SettingsDraft.get("launcher", "systemdServicesOnly")
        onChecked: value => SettingsDraft.set("launcher", "systemdServicesOnly", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "KeePassXC vault path"
        value: SettingsDraft.get("launcher", "keepassVault")
        onEdited: value => SettingsDraft.set("launcher", "keepassVault", value)
        type: SettingsOption.Type.TextField
    }
}
