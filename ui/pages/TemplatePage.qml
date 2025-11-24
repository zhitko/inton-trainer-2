import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8

import by.intontrainer.wavfile 1.0

import "../components"
import "../utils"


Page {
    property string filePath: ""

    title: filePath.substring(filePath.lastIndexOf('/') + 1)

    WavFileApi {
        id: wavFileApi
    }

    Component.onCompleted: {
        let wavFile = wavFileApi.openWavFile(filePath)
        let cuePoints = wavFileApi.getCuePoints(wavFile)
        let waveData = wavFileApi.getWaveData(wavFile)
        waveFormGraph.waveData = waveData
        waveFormGraph.cuePoints = cuePoints
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        PlayButton {
            id: playButton
            width: 32
            height: 32
            file: filePath
        }

        WaveFormGraph {
            id: waveFormGraph
            width: parent.width
            height: 400
        }
    }

}
