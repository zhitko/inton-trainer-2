import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 6.8
import "../utils"

Item {
    property bool showEmpty: true
    property string emptyMessage: qsTr("No items found")
    
    visible: showEmpty
    
    Text {
        text: emptyMessage
        font.pixelSize: AppScale.fs(18)
        color: Theme.onSurfaceVariant(Material.theme)
        anchors.centerIn: parent
        opacity: 0.7
    }
}
