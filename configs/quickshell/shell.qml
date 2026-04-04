import Quickshell // for ShellRoot and PanelWindow
import QtQuick // for Text
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.UPower

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30

            // Hyprland Workspaces
            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    color: '#2b2b2b'
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        Repeater {
                            model: 10

                            // TODO add 'fullscreen' check and different color for that
                            delegate: Rectangle {
                                function wsById(id) {
                                    for (var i = 0; i < Hyprland.workspaces.values.length; ++i) {
                                        var w = Hyprland.workspaces.values[i];
                                        if (w.id === id)
                                            return w;
                                    }
                                    return null;
                                }
                                readonly property HyprlandWorkspace workspace: wsById(index + 1)
                                readonly property bool focused: workspace !== null ? workspace.focused : false

                                color: focused ? 'teal' : (workspace != null ? '#4d4d4d' : '#353535')
                                implicitHeight: 12
                                implicitWidth: 12
                                radius: 999
                            }
                        }
                    }
                }

                // Middle section with time
                Rectangle {
                    id: clock
                    color: '#2b2b2b'
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property date now: new Date()

                    Timer {
                        id: tick
                        interval: 60000
                        running: true
                        repeat: true
                        onTriggered: clock.now = new Date()
                    }

                    Text {
                        anchors.centerIn: parent
                        Layout.fillWidth: true
                        color: '#c6c6c6'
                        font.pixelSize: 14
                        text: Qt.formatDateTime(clock.now, "h:mm ap")
                    }
                }

                // Final right section with battery and wifi
                Rectangle {
                    color: '#2b2b2b'
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        readonly property var dev: UPower.displayDevice
                        color: '#c6c6c6'
                        font.pixelSize: 14

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        Layout.fillWidth: true
                        text: (Math.round(dev.percentage * 100)) + "%" + (dev.state === UPowerDeviceState.Charging ? '+' : '')
                    }
                }
            }
        }
    }
}
