import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import by.intontrainer.audio 1.0
import QtQuick.Controls.Material 6.8

import "../components"


Page {
    property string lastRecordedFile: ""

    Material.theme: themeSwitch.checked ? Material.Dark : Material.Light

    AudioApi {
        id: audioApi
    }

    RoundButton {
        id: recordButton
        anchors.centerIn: parent
        width: 100
        height: 100
        radius: 50

        background: Label {
            font.family: Icons.familySolid
            font.bold: true
            text: audioApi.isRecording ? Icons.faMicrophoneLines : Icons.faMicrophone
            Material.foreground: audioApi.isRecording ? Material.DeepOrange : Material.primaryTextColor
            anchors.centerIn: parent
            font.pixelSize: parent.width / 2
            horizontalAlignment: Label.AlignHCenter
        }

        onClicked: {
            if (audioApi.isRecording) {
                audioApi.stopRecording()
                lastRecordedFile = audioApi.saveWavFile()
            } else {
                lastRecordedFile = ""
                audioApi.startRecording()
            }
        }
    }

    ProgressBar {
        id: volumeIndicator
        anchors.top: recordButton.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 100
        value: audioApi.audioLevel
        visible: audioApi.isRecording
    }

    PlayButton {
        anchors.top: volumeIndicator.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 50
        height: 50
        file: lastRecordedFile
    }
}
