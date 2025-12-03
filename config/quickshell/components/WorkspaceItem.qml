import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Rectangle {
    required property int number
    required property bool active

    width: 20
    height: 20
    color: active ? "#FFFFFF" : "#222222"
    Layout.alignment: Qt.AlignHCenter

    Text {
        anchors.centerIn: parent
        text: number
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        font.bold: active
        color: active ? "#000000" : "#888888"
    }

    TapHandler {
        onTapped: Hyprland.dispatch(`workspace ${parent.number}`)
    }
}
