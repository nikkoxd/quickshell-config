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
}
