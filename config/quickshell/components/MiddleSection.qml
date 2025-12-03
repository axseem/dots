import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

ColumnLayout {
    spacing: 0
    Layout.alignment: Qt.AlignHCenter

    // Active Window Title
    Item {
        width: 38
        height: 150
        Layout.alignment: Qt.AlignHCenter
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
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Separator { Layout.topMargin: 20 }
}
