import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

ColumnLayout {
    spacing: 0
    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
    Layout.topMargin: 9


    // Time Display
    Column {
        width: 38
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 9
        spacing: 0
        
        property var date: new Date()
        Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.date = new Date() }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(parent.date, "HH")
            font.family: "JetBrains Mono"
            font.pixelSize: 16
            color: "white"
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(parent.date, "mm")
            font.family: "JetBrains Mono"
            font.pixelSize: 16
            color: "#888888"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Separator {}

    // Notification Bell
    FigmaIcon {
        pathData: "M5 19q-.425 0-.712-.288T4 18t.288-.712T5 17h1v-7q0-2.075 1.25-3.687T10.5 4.2v-.7q0-.625.438-1.062T12 2t1.063.438T13.5 3.5v.7q2 .5 3.25 2.113T18 10v7h1q.425 0 .713.288T20 18t-.288.713T19 19zm7 3q-.825 0-1.412-.587T10 20h4q0 .825-.587 1.413T12 22"
        onClicked: Hyprland.dispatch("exec swaync-client -t -sw")
    }

    TrayPopup {
        id: trayPopup
    }

    // Background Processes
    FigmaIcon {
        iconColor: "#888888"
        pathData: "M8 16h12V6H8zm0 2q-.825 0-1.412-.587T6 16V4q0-.825.588-1.412T8 2h12q.825 0 1.413.588T22 4v12q0 .825-.587 1.413T20 18zm-4 4q-.825 0-1.412-.587T2 20V7q0-.425.288-.712T3 6t.713.288T4 7v13h13q.425 0 .713.288T18 21t-.288.713T17 22zM8 4v12z"
        onClicked: trayPopup.visible = !trayPopup.visible
    }

    Separator {}

    // Wifi
    FigmaIcon {
        pathData: "M12 7q-2.2 0-4.288.688T3.875 9.724q-.5.4-1.137.388T1.65 9.65q-.425-.425-.425-1.05t.5-1q2.2-1.75 4.838-2.675T12 4q2.825 0 5.45.925T22.275 7.6q.5.375.5 1t-.425 1.05q-.45.45-1.088.463t-1.137-.388q-1.75-1.35-3.825-2.037T12 7m0 6q-1.025 0-1.987.263t-1.838.787q-.55.35-1.187.325T5.9 13.9q-.425-.425-.413-1.037T6 11.9q1.325-.925 2.85-1.412T12 10t3.15.488T18 11.9q.5.35.513.963T18.1 13.9q-.45.45-1.088.475t-1.187-.325q-.875-.525-1.837-.788T12 13m0 7q-.825 0-1.412-.587T10 18t.588-1.412T12 16t1.413.588T14 18t-.587 1.413T12 20"
        onClicked: Hyprland.dispatch("exec nm-connection-editor")
    }

    // Bluetooth
    FigmaIcon {
        iconColor: "#888888"
        pathData: "M5 13.5q-.625 0-1.062-.437T3.5 12t.438-1.062T5 10.5t1.063.438T6.5 12t-.437 1.063T5 13.5m14 0q-.625 0-1.062-.437T17.5 12t.438-1.062T19 10.5t1.063.438T20.5 12t-.437 1.063T19 13.5m-8 7.075V14.4l-3.9 3.9q-.275.275-.7.275t-.7-.275t-.275-.7t.275-.7l4.9-4.9l-4.9-4.9q-.275-.275-.275-.7t.275-.7t.7-.275t.7.275L11 9.6V3.425q0-.45.3-.737T12 2.4q.2 0 .375.075t.325.225L17 7q.15.15.213.325t.062.375t-.062.375T17 8.4L13.4 12l3.6 3.6q.15.15.213.325t.062.375t-.062.375T17 17l-4.3 4.3q-.15.15-.325.225T12 21.6q-.4 0-.7-.288t-.3-.737M13 9.6l1.9-1.9L13 5.85zm0 8.55l1.9-1.85l-1.9-1.9z"
        onClicked: Hyprland.dispatch("exec blueman-manager")
    }

    // Battery
    FigmaIcon {
        pathData: "M4 18q-1.25 0-2.125-.875T1 15V9q0-1.25.875-2.125T4 6h13.5q1.25 0 2.125.875T20.5 9v6q0 1.25-.875 2.125T17.5 18zm0-2h13.5q.425 0 .713-.288T18.5 15V9q0-.425-.288-.712T17.5 8H4q-.425 0-.712.288T3 9v6q0 .425.288.713T4 16m17.5-1.5v-5h.5q.425 0 .713.288T23 10.5v3q0 .425-.288.713T22 14.5zM4 14v-4q0-.425.288-.712T5 9h11.5q.425 0 .713.288T17.5 10v4q0 .425-.288.713T16.5 15H5q-.425 0-.712-.288T4 14"
        onClicked: Hyprland.dispatch("exec", "ghostty -e btop")
    }

    // Volume
    FigmaIcon {
        pathData: "M19 11.975q0-2.075-1.1-3.787t-2.95-2.563q-.375-.175-.55-.537t-.05-.738q.15-.4.538-.575t.787 0Q18.1 4.85 19.55 7.063T21 11.974t-1.45 4.913t-3.875 3.287q-.4.175-.788 0t-.537-.575q-.125-.375.05-.737t.55-.538q1.85-.85 2.95-2.562t1.1-3.788M7 15H4q-.425 0-.712-.288T3 14v-4q0-.425.288-.712T4 9h3l3.3-3.3q.475-.475 1.088-.213t.612.938v11.15q0 .675-.612.938T10.3 18.3zm9.5-3q0 1.05-.475 1.988t-1.25 1.537q-.25.15-.513.013T14 15.1V8.85q0-.3.263-.437t.512.012q.775.625 1.25 1.575t.475 2"
        onClicked: Hyprland.dispatch("exec pavucontrol")
    }

    // CPU/Memory
    FigmaIcon {
        pathData: "M9 14v-4q0-.425.288-.712T10 9h4q.425 0 .713.288T15 10v4q0 .425-.288.713T14 15h-4q-.425 0-.712-.288T9 14m0 6v-1H7q-.825 0-1.412-.587T5 17v-2H4q-.425 0-.712-.288T3 14t.288-.712T4 13h1v-2H4q-.425 0-.712-.288T3 10t.288-.712T4 9h1V7q0-.825.588-1.412T7 5h2V4q0-.425.288-.712T10 3t.713.288T11 4v1h2V4q0-.425.288-.712T14 3t.713.288T15 4v1h2q.825 0 1.413.588T19 7v2h1q.425 0 .713.288T21 10t-.288.713T20 11h-1v2h1q.425 0 .713.288T21 14t-.288.713T20 15h-1v2q0 .825-.587 1.413T17 19h-2v1q0 .425-.288.713T14 21t-.712-.288T13 20v-1h-2v1q0 .425-.288.713T10 21t-.712-.288T9 20m8-3V7H7v10z"
        onClicked: Hyprland.dispatch("exec ghostty -e btop")
    }
    
    Separator {}
}
