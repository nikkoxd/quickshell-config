import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    SettingsOption {
        title: "Show results with empty query"
        value: Config.launcher.showResultsWithEmptyQuery
        onChecked: value => Config.launcher.showResultsWithEmptyQuery = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Sort results by usage"
        value: Config.launcher.sortByUsage
        onChecked: value => Config.launcher.sortByUsage = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Custom entries behind prefix"
        value: Config.launcher.useCustomEntriesPrefix
        onChecked: value => Config.launcher.useCustomEntriesPrefix = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Custom entries prefix"
        visible: Config.launcher.useCustomEntriesPrefix
        value: Config.launcher.customEntriesPrefix
        onEdited: value => Config.launcher.customEntriesPrefix = value
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Run command prefix"
        value: Config.launcher.commandPrefix
        onEdited: value => Config.launcher.commandPrefix = value
        type: SettingsOption.Type.TextField
    }
}
