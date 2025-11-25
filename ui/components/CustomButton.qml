import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 6.8

RoundButton {
    id: control
    property bool showLabel: false
    property string label: ""

    width: 50
    height: width
    radius: width / 2

    background: Rectangle {
        radius: control.radius
        anchors.fill: parent
        Label {
            id: label
            font.family: Icons.familySolid
            font.bold: true
            text: control.label
            anchors.left: parent.left
            anchors.leftMargin: parent.width / 3
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            font.pixelSize: parent.width / 2
            verticalAlignment: Label.AlignVCenter
        }
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                parent.color = Material.rippleColor
                label.font.pixelSize+=4
            }
            onExited: {
                parent.color = Material.backgroundColor
                label.font.pixelSize-=4
            }
        }
    }
}
