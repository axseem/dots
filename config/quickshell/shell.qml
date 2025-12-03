import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes 1.0
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import "./components"

ShellRoot {


    // -------------------------------------------------------------------------
    // Main Window
    // -------------------------------------------------------------------------

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
        }
        implicitWidth: 40
        color: "#000000"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Main Vertical Layout
            ColumnLayout {
                Layout.preferredWidth: 38
                Layout.fillHeight: true
                spacing: 0

                TopSection {}

                BottomSection {
                    Layout.fillHeight: true
                }
            }

            // Border
            Rectangle {
                Layout.preferredWidth: 2
                Layout.fillHeight: true
                color: "#222222"
            }
        }
    }
}