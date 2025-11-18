import QtQuick
import QtQuick.Controls
import "../components/cards"

Page {
    title: "Home"

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text {
            text: "Welcome to IntonTrainer"
            font.pixelSize: 24
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
            spacing: 16
            width: parent.width

            Card {
                text: "Templates"
                width: parent.width
                onClicked: stackView.push("TemplatesPage.qml")
            }

            Card {
                text: "My Records"
                width: parent.width
                onClicked: stackView.push("RecordsPage.qml")
            }

            Card {
                text: "Settings"
                width: parent.width
            }
        }
    }
}
