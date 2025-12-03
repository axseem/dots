import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

ColumnLayout {
    spacing: 0
    Layout.alignment: Qt.AlignHCenter
    Layout.bottomMargin: 9
    Layout.topMargin: 9

    // Active Window Title
    Item {
        width: 38
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 4
        clip: true // Cut off text if too long

        Text {
            anchors.centerIn: parent
            // Uses Hyprland service to get title
            text: (Hyprland.activeToplevel && Hyprland.activeToplevel.title) ? Hyprland.activeToplevel.title : "Desktop"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            color: "white"
            rotation: -90
            elide: Text.ElideRight
            width: parent.height
            height: parent.width
            verticalAlignment: Text.AlignVCenter
        }
    }

    Separator { Layout.topMargin: 9; Layout.bottomMargin: 9 }

    // Workspaces
    Column {
        Layout.alignment: Qt.AlignHCenter
        spacing: 0
        Layout.bottomMargin: 9
        
        Repeater {
            model: Hyprland.workspaces.values.length
            delegate: Column {
                spacing: 0
                
                property var workspace: Hyprland.workspaces.values[Hyprland.workspaces.values.length - 1 - index]
                
                WorkspaceItem {
                    number: workspace.id
                    active: workspace.focused
                }

                // Separator dots between numbers
                Rectangle {
                    width: 20
                    height: 1
                    color: "#333333"
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: index < Hyprland.workspaces.values.length - 1
                }
            }
        }
    }

    Separator {}



    // Date (Day/Month)
    Column {
        Layout.alignment: Qt.AlignHCenter
        width: 38; height: 60
        spacing: 0
        Layout.topMargin: 9
        
        property var date: new Date()
        // Timer reused from top
        Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.date = new Date() }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(parent.date, "ddd").substring(0, 2) // e.g. "Mo"
            font.family: "JetBrains Mono"
            font.pixelSize: 16
            color: "#888888" 
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(parent.date, "dd") // e.g. "24"
            font.family: "JetBrains Mono"
            font.pixelSize: 16
            color: "white"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
