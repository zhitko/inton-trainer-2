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
        let wavFile = wavFileApi.openWavFile(filePath);
        let cuePoints = wavFileApi.getCuePoints(wavFile);
        let waveData = wavFileApi.getWaveData(wavFile);
        waveFormGraph.waveData = waveData;
        waveFormGraph.cuePoints = cuePoints;

        // Extract pitch data
        let pitchData = wavFileApi.getPitch(wavFile, "Harvest"      // algorithm
        , 80.0        // frame shift
        , 16000.0     // sample rate
        , 20.0        // min F0
        , 600.0       // max F0
        , 0.3         // voicing threshold
        , "PITCH"         // output format
        );
        pitchWaveFormGraph.waveData = pitchData;
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
            showLabel: true
        }

        WaveFormGraph {
            id: waveFormGraph
            width: parent.width
            height: 300
        }

        Text {
            text: "Pitch (F0)"
            font.pixelSize: 14
            font.bold: true
        }

        WaveFormGraph {
            id: pitchWaveFormGraph
            width: parent.width
            height: 200
        }
    }
}
