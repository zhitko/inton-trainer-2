import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import "../utils"

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 56
    radius: 28
    color: Theme.surfaceVariant(Material.theme)

    property alias text: searchInputField.text

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.15)
        blur: 0.34
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Text {
            text: Icons.faMagnifyingGlass
            font.family: Icons.familySolid
            font.weight: Font.Black
            font.pixelSize: AppScale.fs(24)
            color: Theme.onSurfaceVariant(Material.theme)
            Layout.alignment: Qt.AlignVCenter
        }

        TextField {
            id: searchInputField
            Layout.fillWidth: true
            placeholderText: qsTr("Search")
            background: null
            font.pixelSize: AppScale.fs(16)
            color: Theme.onSurfaceVariant(Material.theme)
        }
    }
}
