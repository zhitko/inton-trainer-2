import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import by.intontrainer.audio 1.0
import QtQuick.Controls.Material 6.8

import "../components"
import "../utils"


Page {
    property string filePath: ""

    title: filePath.substring(filePath.lastIndexOf('/') + 1)

    PlayButton {
        id: playButton
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        width: 32
        height: 32
        file: filePath
    }
}
