import QtQuick
import QtQuick.Controls.Material 6.8
import QtQuick.Controls.Basic
import "../../utils"

Rectangle {
    id: card
    width: 150
    height: 100
    radius: 16
    border.color: mouseArea.containsMouse ? Theme.primary(Material.theme) : Theme.outlineVariant(Material.theme)
    border.width: 1
    scale: mouseArea.containsMouse ? 1.05 : 1.0
    color: mouseArea.containsMouse ? Theme.surfaceContainerLow(Material.theme) : Theme.surface(Material.theme)

    Behavior on scale {
        NumberAnimation {
            duration: 100
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 100
        }
    }

    readonly property alias title: cardText
    readonly property alias icon: cardIcon
    signal clicked

    Text {
        id: cardIcon
        anchors.right: cardText.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 16
        color: mouseArea.containsMouse ? Theme.secondary(Material.theme) : Theme.onSurface(Material.theme)
    }

    Text {
        id: cardText
        anchors.centerIn: parent
        font.pixelSize: 16
        color: Theme.onSurface(Material.theme)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: card.clicked()
        hoverEnabled: true
    }
}
