import QtQuick
import QtQuick.Controls
import by.intontrainer.file 1.0
import QtQuick.Controls.Material 6.8

import "../components"

Page {
    title: "Records"

    Material.theme: themeSwitch.checked ? Material.Dark : Material.Light

    FileApi {
        id: fileApi
    }

    property var fileTree: fileApi.getFiles("data/records", ["*.wav"])

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16

        FileTreeView {
            model: fileTree
            path: "data/records"
        }
    }
}
