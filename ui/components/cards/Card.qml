import QtQuick
import QtQuick.Controls.Material 6.8
import QtQuick.Controls.Basic

Rectangle {
    id: card
    width: 150
    height: 100
    radius: 8
    border.color: mouseArea.containsMouse ? Material.primary : Material.dividerColor
    border.width: 1
    scale: mouseArea.containsMouse ? 1.05 : 1.0
    color: mouseArea.containsMouse ? Material.rippleColor : Material.backgroundColor

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
        color: mouseArea.containsMouse ? Material.accentColor : Material.primaryTextColor
    }

    Text {
        id: cardText
        anchors.centerIn: parent
        font.pixelSize: 16
        color: Material.primaryTextColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: card.clicked()
        hoverEnabled: true
    }
}

