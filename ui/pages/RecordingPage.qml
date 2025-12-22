import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import by.intontrainer.audio 1.0
import QtQuick.Controls.Material 6.8

import "../components"

Page {
    property string lastRecordedFile: ""

    AudioApi {
        id: audioApi
    }

    RoundButton {
        id: recordButton
        anchors.centerIn: parent
        width: 100
        height: 100
        radius: 50

        hoverEnabled: true

        background: Label {
            font.family: Icons.familySolid
            font.bold: true
            text: audioApi.isRecording ? Icons.faMicrophoneLines : Icons.faMicrophone
            color: audioApi.isRecording ? Theme.error(Material.theme) : Theme.onSurface(Material.theme)
            anchors.centerIn: parent
            font.pixelSize: recordButton.hovered ? parent.width / 2 + 5 : parent.width / 2
            horizontalAlignment: Label.AlignHCenter
        }

        onClicked: {
            if (audioApi.isRecording) {
                audioApi.stopRecording();
                lastRecordedFile = audioApi.saveWavFile();
            } else {
                lastRecordedFile = "";
                audioApi.startRecording();
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
        id: playButton
        anchors.top: volumeIndicator.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 50
        height: 50
        file: lastRecordedFile
        showLabel: true
    }

    CustomButton {
        id: openButton
        anchors.top: playButton.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 50
        height: 50
        visible: !!lastRecordedFile
        showLabel: true
        label: Icons.faWaveSquare + " " + qsTr("Open")
        onClicked: {
            console.log("ui/pages/RecordsPage.qml:onFileClicked:", lastRecordedFile);
            stackView.push("TemplatePage.qml", {
                "filePath": lastRecordedFile
            });
        }
    }
}
