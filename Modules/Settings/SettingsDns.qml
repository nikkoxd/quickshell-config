pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Services

// The preset list behind the DNS view. Addresses are edited as comma separated
// text and stored as lists in Config/dns.json. The DHCP entry is not listed
// here: DnsService always offers it first.
ColumnLayout {
    id: root

    spacing: 30
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    function _servers() {
        return JSON.parse(JSON.stringify(Config.dns || []));
    }

    function _parseList(text) {
        return text.split(",").map(v => v.trim()).filter(v => v !== "");
    }

    function setField(index, key, value) {
        const servers = root._servers();
        if (!servers[index])
            return;
        servers[index][key] = value;
        Config.saveDns(servers);
    }

    function remove(index) {
        const servers = root._servers();
        servers.splice(index, 1);
        Config.saveDns(servers);
    }

    function add() {
        const servers = root._servers();
        servers.push({
            name: "New server",
            ipv4: [],
            ipv6: []
        });
        Config.saveDns(servers);
    }

    ColumnLayout {
        spacing: 10
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            SettingsSection {
                text: "DNS servers"
            }

            Item {
                Layout.fillWidth: true
            }

            ThemedText {
                icon: true
                text: "plus-circle"
                font.pixelSize: 18
                color: addHover.hovered ? Config.colorscheme.accent : Config.colorscheme.fg

                HoverHandler {
                    id: addHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.add()
                }
            }
        }

        ThemedText {
            text: "Applied to the active NetworkManager connection. Switch between them in the DNS view."
            opacity: 0.7
        }

        Repeater {
            model: Config.dns

            RowLayout {
                id: server

                required property int index
                required property var modelData

                spacing: 10
                Layout.fillWidth: true

                TextField {
                    text: server.modelData.name || ""
                    placeholderText: "Name"
                    onEditingFinished: root.setField(server.index, "name", text)
                    font.pixelSize: 16
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 150
                }

                TextField {
                    text: (server.modelData.ipv4 || []).join(", ")
                    placeholderText: "IPv4 servers"
                    onEditingFinished: root.setField(server.index, "ipv4", root._parseList(text))
                    font.pixelSize: 16
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true
                }

                TextField {
                    text: (server.modelData.ipv6 || []).join(", ")
                    placeholderText: "IPv6 servers"
                    onEditingFinished: root.setField(server.index, "ipv6", root._parseList(text))
                    font.pixelSize: 16
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true
                }

                ThemedText {
                    icon: true
                    text: "x-circle"
                    font.pixelSize: 18
                    color: removeHover.hovered ? Config.colorscheme.accent : Config.colorscheme.fg

                    HoverHandler {
                        id: removeHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.remove(server.index)
                    }
                }
            }
        }
    }

    ColumnLayout {
        spacing: 10
        Layout.fillWidth: true

        SettingsSection {
            text: "Current"
        }

        ThemedText {
            text: DnsService.connectionName === "" ? "No active connection" : DnsService.connectionName + " — " + (DnsService.currentIpv4.concat(DnsService.currentIpv6).join(", ") || "servers from DHCP")
            opacity: 0.7
        }
    }
}
