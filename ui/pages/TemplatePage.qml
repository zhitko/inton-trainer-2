import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8

import by.intontrainer.wavfile 1.0

import "../components"
import "../utils"


Page {
    property string filePath: ""
    property var wavFile: null

    title: filePath.substring(filePath.lastIndexOf('/') + 1)

    WavFileApi {
        id: wavFileApi
    }

    Component.onCompleted: {
        let wavFile = wavFileApi.openWavFile(filePath)
        console.log("ui/pages/TemplatePage.qml:onCompleted wavFile", filePath)
        let cuePoints = wavFileApi.getCuePoints(wavFile)
        console.log("ui/pages/TemplatePage.qml:onCompleted cuePoints", cuePoints)
    }

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
