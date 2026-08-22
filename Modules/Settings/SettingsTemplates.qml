pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

// One toggle per entry in Config/templates.json. Each entry is rendered by
// whichever generator is active (Templates/Iris/<file> or
// Templates/Matugen/<file>) into the same output path, so toggling a template
// off stops both generators from touching that file. Output paths, post hooks
// and new entries are edited in the file itself.
ColumnLayout {
    id: root

    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    function setEnabled(name, enabled) {
        const entries = JSON.parse(JSON.stringify(Config.templates));
        entries[name] = Object.assign({
            output: "",
            postHook: ""
        }, entries[name] || {});
        entries[name].enabled = enabled;
        Config.saveTemplates(entries);
    }

    RowLayout {
        Layout.fillWidth: true

        SettingsSection {
            text: "Templates"
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            color: editHover.hovered ? Config.colorscheme.accent : Config.colorscheme.surface
            radius: 10
            implicitWidth: editLabel.implicitWidth + 40
            implicitHeight: 40

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            HoverHandler {
                id: editHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: TemplateService.openRegistry()
            }

            ThemedText {
                id: editLabel
                anchors.centerIn: parent
                text: "Edit templates.json"
                color: editHover.hovered ? Config.colorscheme.bg : Config.colorscheme.fg
                font.pixelSize: 16
            }
        }
    }

    Repeater {
        model: TemplateService.names

        SettingsOption {
            id: option

            required property string modelData

            title: option.modelData
            value: TemplateService.entry(option.modelData).enabled
            onChecked: enabled => root.setEnabled(option.modelData, enabled)
            type: SettingsOption.Type.Switch
        }
    }
}
