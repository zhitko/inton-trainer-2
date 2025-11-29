import QtQuick
import QtQuick.Controls
import by.intontrainer.file 1.0
import QtQuick.Controls.Material 6.8

import "../components"

Page {
    id: templatesPage
    title: qsTr("Templates")

    Material.theme: window.theme

    FileApi {
        id: fileApi
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        FileTreeView {
            model: fileApi.getFiles("data/templates", ["*.wav"])
            path: "data/templates"
            onFileClicked: filePath => {
                console.log("ui/pages/TemplatesPage.qml:onFileClicked:", filePath);
                stackView.push("TemplatePage.qml", {
                    "filePath": filePath
                });
            }
        }
    }
}
