import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.audio 1.0
import "../utils"

ColumnLayout {
    id: root
    spacing: 8

    property string filePath: ""
    readonly property bool isRecording: audioApi.isRecording
    readonly property real audioLevel: audioApi.audioLevel
    signal clicked
    signal recordingFinished(string filePath)

    AudioApi {
        id: audioApi
        onPermissionResultReceived: function(granted) {
            if (granted) {
                Logger.debug("Permission granted, starting recording");
                root.filePath = "";
                audioApi.startRecording();
                Logger.debug("Recording started");
                root.clicked();
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
            root.filePath = audioApi.saveWavFile();
            root.recordingFinished(root.filePath);
            Logger.debug("Auto-stop: Recording finished automatically: " + root.filePath);
        }
        onIsRecordingChanged: {
            if (!audioApi.isRecording && root.filePath === "") {
                // Recording was stopped automatically (auto-stop), save the file
                root.filePath = audioApi.saveWavFile();
                root.recordingFinished(root.filePath);
                Logger.debug("Auto-stop: Recording finished automatically: " + root.filePath);
            }
        }
    }

    Item {
        id: buttonContainer
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 84
        Layout.preferredHeight: 84

        Rectangle {
            id: outerCircle
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            // MD3 outlined button - uses outline color with 1dp stroke
            border.color: Theme.outline(Material.theme)
            border.width: 1

            Behavior on border.color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        Rectangle {
            id: innerCircle
            anchors.centerIn: parent
            width: root.isRecording ? 68 : 76
            height: width
            radius: width / 2
            color: Theme.error(Material.theme)

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.isRecording ? Icons.faStop : Icons.faMicrophone
                font.family: Icons.familySolid
                font.weight: Font.Black
                font.pixelSize: AppScale.fs(28)
                color: Theme.onError(Material.theme)
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (audioApi.isRecording) {
                        audioApi.stopRecording();
                        root.filePath = audioApi.saveWavFile();
                        root.recordingFinished(root.filePath);
                        Logger.debug("Recording finished: " + root.filePath);
                    } else {
                        // Request microphone permission (no-op on desktop)
                        if (!audioApi.requestAudioPermission()) {
                            // Permission request is pending — will start in callback
                            return;
                        }
                        root.filePath = "";
                        audioApi.startRecording();
                        Logger.debug("Recording started");
                    }
                    root.clicked();
                }
            }
        }

        // Pulse Animation for recording
        Rectangle {
            id: pulse
            anchors.centerIn: parent
            width: innerCircle.width
            height: innerCircle.height
            radius: width / 2
            color: Theme.error(Material.theme)
            opacity: 0
            z: -1
            scale: 1.0

            SequentialAnimation {
                running: root.isRecording
                loops: Animation.Infinite

                onRunningChanged: {
                    if (!running) {
                        pulse.scale = 1.0;
                        pulse.opacity = 0;
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: pulse
                        property: "scale"
                        from: 1.0
                        to: 1.6
                        duration: 1200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: pulse
                        property: "opacity"
                        from: 0.6
                        to: 0
                        duration: 1200
                        easing.type: Easing.OutCubic
                    }
                }
                PropertyAction {
                    target: pulse
                    property: "scale"
                    value: 1.0
                }
                PropertyAction {
                    target: pulse
                    property: "opacity"
                    value: 0
                }
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.isRecording ? qsTr("Recording") : qsTr("Record")
        font.pixelSize: AppScale.fs(14)
        font.weight: 600
        color: Theme.onSurface(Material.theme)
    }
}
