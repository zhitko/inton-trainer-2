import QtQuick
import QtQuick.Controls
import by.intontrainer.file 1.0
import "../components"

Page {
    title: "Templates"

    FileApi {
        id: fileApi
    }

    property var fileTree: fileApi.getFiles("data/templates", ["*.wav"])

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        FileTreeView {
            model: fileTree
            path: "data/templates"
        }
    }
}
