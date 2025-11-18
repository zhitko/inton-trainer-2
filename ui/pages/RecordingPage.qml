import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import by.intontrainer.audio 1.0
import "../components"


Page {
    property string lastRecordedFile: ""

    AudioAPI {
        id: audioAPI
    }

    RoundButton {
        id: recordButton
        anchors.centerIn: parent
        width: 100
        height: 100
        radius: 50

        background: Image {
            source: audioAPI.isRecording ? "../../res/icons/microphone_off.svg" : "../../res/icons/microphone_on.svg"
            anchors.fill: parent
            anchors.margins: 15
            mipmap: true
        }

        onClicked: {
            if (audioAPI.isRecording) {
                audioAPI.stopRecording()
                lastRecordedFile = audioAPI.saveFile()
            } else {
                lastRecordedFile = ""
                audioAPI.startRecording()
            }
        }
    }

    ProgressBar {
        id: volumeIndicator
        anchors.top: recordButton.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 100
        value: audioAPI.audioLevel
        visible: audioAPI.isRecording
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
