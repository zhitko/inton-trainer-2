import QtQuick
import QtQuick.Controls.Material 6.8
import QtQuick.Controls.Basic
import QtQuick.Effects
import "../../utils"

Rectangle {
    id: card
    width: 150
    height: 100
    radius: 12 // MD3 medium shape token
    border.color: Theme.outline(Material.theme)
    border.width: 1
    color: mouseArea.containsMouse ? Theme.surfaceContainerLow(Material.theme) : Theme.surface(Material.theme)

    // MD3 State Layer - hover effect (8% opacity)
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.onSurface(Material.theme)
        opacity: mouseArea.containsMouse ? 0.08 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }

    // MD3 Elevation shadow on hover
    layer.enabled: mouseArea.containsMouse
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.15)
        blur: 0.34
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
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
