import QtQuick
import QtQuick.Controls.Material 6.8

Item {
    property string sectionText: ""
    
    width: ListView.view ? ListView.view.width : 0
    height: 40
    visible: sectionText !== ""

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: sectionText
        font.pixelSize: 16
        font.weight: 700
        color: Theme.onSurfaceVariant(Material.theme)
        opacity: 0.7
    }
}
