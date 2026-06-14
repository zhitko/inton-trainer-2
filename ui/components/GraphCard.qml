import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import "../utils"

Frame {
    id: root
    property string title: ""
    default property alias content: contentItem.data

    Layout.fillWidth: true
    padding: 16

    background: Rectangle {
        color: Theme.surfaceContainerLow(Material.theme)
        radius: 16
        border.color: Theme.outlineVariant(Material.theme)
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            text: root.title
            font.pixelSize: AppScale.fs(18)
            font.weight: Font.Medium
            color: Theme.primary(Material.theme)
            visible: root.title !== ""
            Layout.fillWidth: true
        }

        Item {
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: 300 // Default height
        }
    }
}
