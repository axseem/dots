import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    property string pathData
    property color iconColor: "white"
    signal clicked()

    // Frame size from Figma
    width: 38; height: 38
    Layout.alignment: Qt.AlignHCenter

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.clicked()
    }

    Shape {
        anchors.centerIn: parent
        // The provided SVGs are on a 0-24 coordinate system.
        width: 24; height: 24

        // Your Figma design specifies icons are 20x20px.
        // We scale the 24px SVG down to 20px (20/24 ≈ 0.833).
        scale: 20/24

        ShapePath {
            strokeWidth: 0
            fillColor: iconColor
            PathSvg { path: pathData }
        }
    }
}
