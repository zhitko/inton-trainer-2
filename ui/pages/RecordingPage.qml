import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import by.intontrainer.audio 1.0
import QtQuick.Controls.Material 6.8

import "../components"
import "../utils"

Page {
    property string lastRecordedFile: ""

    AudioApi {
        id: audioApi
        onPermissionResultReceived: function(granted) {
            if (granted) {
                Logger.debug("Permission granted, starting recording");
                audioApi.startRecording();
            } else {
                Logger.warning("Microphone permission denied");
            }
        }
    }

    // Handle auto-stop recording - when recording stops automatically
    Connections {
        target: audioApi
        onRecordingFinished: {
            // Auto-stop triggered - save the file
            lastRecordedFile = audioApi.saveWavFile();
            Logger.debug("Auto-stop: Recording finished automatically: " + lastRecordedFile);
        }
        onIsRecordingChanged: {
            if (!audioApi.isRecording && lastRecordedFile === "") {
                // Recording was stopped automatically (auto-stop), save the file
                lastRecordedFile = audioApi.saveWavFile();
                Logger.debug("Auto-stop: Recording finished automatically: " + lastRecordedFile);
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - AppScale.pagePadding * 2, 280)
        spacing: AppScale.isCompact ? 8 : 12

        RoundButton {
            id: recordButton
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: AppScale.isCompact ? 84 : 100
            Layout.preferredHeight: AppScale.isCompact ? 84 : 100
            width: Layout.preferredWidth
            height: Layout.preferredHeight
            radius: width / 2

            hoverEnabled: true

            background: Label {
                font.family: Icons.familySolid
                font.weight: Font.Black
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
                    if (!audioApi.requestAudioPermission()) {
                        return;
                    }
                    audioApi.startRecording();
                }
            }
        }

        ProgressBar {
            id: volumeIndicator
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: AppScale.isCompact ? 84 : 100
            value: audioApi.audioLevel
            visible: audioApi.isRecording
        }

        PlayButton {
            id: playButton
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            file: lastRecordedFile
            showLabel: true
        }

        CustomButton {
            id: openButton
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            visible: !!lastRecordedFile
            showLabel: true
            label: Icons.faWaveSquare + " " + qsTr("Open")
            onClicked: {
                console.log("ui/pages/RecordingPage.qml:onFileClicked:", lastRecordedFile);
                stackView.push("TemplatePage.qml", {
                    "userFilePath": lastRecordedFile
                });
            }
        }
    }
}
