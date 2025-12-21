import QtQuick
import QtQuick.Controls
import by.intontrainer.file 1.0
import QtQuick.Controls.Material 6.8

import "../components"

Page {
    id: templatesPage
    title: qsTr("Templates")

    property string path: "data/templates"

    Material.theme: window.theme

    FileApi {
        id: fileApi
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        FileTreeView {
            model: fileApi.getFiles(templatesPage.path, ["*.wav"])
            path: templatesPage.path
            onFileClicked: filePath => {
                console.log("ui/pages/TemplatesPage.qml:onFileClicked:", filePath);
                stackView.push("TemplatePage.qml", {
                    "filePath": filePath
                });
            }
        }
    }
}
