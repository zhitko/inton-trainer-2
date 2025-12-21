import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../utils"

Rectangle {
    id: root

    property string title: ""
    property string value: ""
    property string icon: ""
    property string iconFamily: Icons.familySolid

    color: "#F5F5F5" // Light grey background
    radius: 12

    implicitWidth: 100
    implicitHeight: 100

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: root.iconFamily
            font.pixelSize: 24
            color: "#1565C0" // Blueish color
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font.pixelSize: 14
            color: "#757575"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.maximumWidth: root.width - 16
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.value
            font.pixelSize: 18
            font.bold: true
            color: "#212121"
        }
    }
}
