import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray

Window {
    id: root
    
    width: 200
    height: Math.max(100, Math.min(flow.implicitHeight + 20, 400))
    
    visible: false

    x: 45
    y: 100

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        
        Flow {
            id: flow
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            
            Repeater {
                model: SystemTray.items
                
                delegate: Rectangle {
                    width: 40
                    height: 40
                    color: mouseArea.containsMouse ? "#333333" : "transparent"
                    radius: 4
                    
                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: modelData.icon
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.activate()
                    }
                    
                    ToolTip {
                        visible: mouseArea.containsMouse
                        text: modelData.title
                    }
                }
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: "No items"
            color: "#888888"
            visible: SystemTray.items.length === 0
            font.family: "JetBrains Mono"
        }
    }
}
