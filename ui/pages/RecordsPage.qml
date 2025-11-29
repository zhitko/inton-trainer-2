import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 6.8

import by.intontrainer.file 1.0

import "../components"

Page {
    title: qsTr("Records")

    Material.theme: window.theme

    FileApi {
        id: fileApi
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        FileTreeView {
            model: fileApi.getFiles("data/records", ["*.wav"])
            path: "data/records"
            canDelete: true
            onFileClicked: filePath => {
                console.log("ui/pages/RecordsPage.qml:onFileClicked:", filePath);
                stackView.push("TemplatePage.qml", {
                    "filePath": filePath
                });
            }
        }
    }
}
