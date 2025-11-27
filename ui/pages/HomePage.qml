import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 6.8

import "../components/cards"

Page {
    title: "Home"

    Material.theme: window.theme

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text {
            text: "Welcome to IntonTrainer"
            font.pixelSize: 24
            anchors.horizontalCenter: parent.horizontalCenter
            color: Material.primaryTextColor
        }

        Flow {
            width: parent.width
            spacing: 16

            Card {
                title.text: "Templates"
                icon.font.family: Icons.familySolid
                icon.font.bold: true
                icon.text: Icons.faFolderTree
                width: parent.width
                onClicked: stackView.push("TemplatesPage.qml")
            }

            Card {
                title.text: "My Records"
                icon.font.family: Icons.familySolid
                icon.font.bold: true
                icon.text: Icons.faBoxArchive
                width: parent.width
                onClicked: stackView.push("RecordsPage.qml")
            }

            Card {
                title.text: "Settings"
                icon.font.family: Icons.familySolid
                icon.font.bold: true
                icon.text: Icons.faGear
                width: parent.width
                onClicked: stackView.push("SettingsPage.qml")
            }
        }
    }
}
