import QtQuick

Rectangle {
    id: card
    width: 150
    height: 100
    radius: 8
    border.color: mouseArea.containsMouse ? "gray" : "lightgray"
    border.width: 1
    scale: mouseArea.containsMouse ? 1.05 : 1.0

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

    property alias text: cardText.text
    signal clicked

    Text {
        id: cardText
        anchors.centerIn: parent
        font.pixelSize: 16
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: card.clicked()
        hoverEnabled: true
    }
}
