import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8
import QtQuick.Layouts
import QtQuick.Effects

import by.intontrainer.wavfile 1.0

import "../components"
import "../utils"

Page {
    id: root
    property string referenceFilePath: ""
    property string userFilePath: ""
    property string titleText: referenceFilePath.substring(referenceFilePath.lastIndexOf('/') + 1).replace(".wav", "")

    title: titleText

    property var referenceWavFileHandle: null
    property var referenceCuePoints: []
    property var referenceWaveData: []

    property var userWavFileHandle: null
    property var userWaveData: []

    WavFileApi {
        id: wavFileApi
    }

    Component.onCompleted: {
        Logger.info("TrainingPage loaded for file: " + referenceFilePath);
        referenceWavFileHandle = wavFileApi.openWavFile(referenceFilePath);
        referenceCuePoints = wavFileApi.getCuePoints(referenceWavFileHandle);
        referenceWaveData = wavFileApi.getWaveData(referenceWavFileHandle);
        updateUMP();
    }

    function updateUMP() {
        if (!referenceWavFileHandle)
            return;

        let pitchData = wavFileApi.getPitch(referenceWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);

        let umpResult = wavFileApi.getUMP(pitchData, referenceCuePoints, 50, 100, 50, referenceWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType]);

        umpGraph.waveData = umpResult.ump;
        umpGraph.cuePoints = umpResult.cuePoints;
    }

    background: Rectangle {
        color: Theme.background(root.Material.theme)
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: parent.width
        clip: true

        ColumnLayout {
            width: scrollView.width - 32
            x: 16
            y: 16
            spacing: 24

            // Stats Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: Theme.secondaryContainer(root.Material.theme)
                radius: 12

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.15)
                    blur: 0.34
                    shadowVerticalOffset: 4
                    shadowHorizontalOffset: 0
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: qsTr("Range:")
                            font.pixelSize: 14
                            color: Theme.onSecondaryContainer(root.Material.theme)
                        }
                        Text {
                            text: "83%"
                            font.pixelSize: 28
                            font.weight: 700
                            color: Theme.primary(root.Material.theme)
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: Theme.outlineVariant(root.Material.theme)
                        opacity: 0.5
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: qsTr("Shape:")
                            font.pixelSize: 14
                            color: Theme.onSurfaceVariant(root.Material.theme)
                        }
                        Text {
                            text: "88%"
                            font.pixelSize: 28
                            font.weight: 700
                            color: Theme.primary(root.Material.theme)
                        }
                    }
                }
            }

            // Comparison Labels and Bars
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: qsTr("Reference range")
                        font.pixelSize: 14
                        font.weight: 600
                        color: Theme.onSurface(root.Material.theme)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        color: Theme.surfaceContainerHighest(root.Material.theme)
                        radius: 4
                        Rectangle {
                            width: parent.width * 0.9
                            height: parent.height
                            color: Theme.primary(root.Material.theme)
                            radius: 4
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: qsTr("My range")
                        font.pixelSize: 14
                        font.weight: 600
                        color: Theme.onSurfaceVariant(root.Material.theme)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        color: Theme.surfaceContainerHighest(root.Material.theme)
                        radius: 4
                        Rectangle {
                            width: parent.width * 0.0
                            height: parent.height
                            color: Theme.secondary(root.Material.theme)
                            radius: 4
                        }
                    }
                }
            }

            // Main Graph
            WaveFormGraph {
                id: umpGraph
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 240
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 32

                PlayRoundButton {
                    filePath: root.referenceFilePath
                    text: qsTr("Play\nReference")
                }

                RecordRoundButton {
                    filePath: root.userFilePath
                }

                PlayRoundButton {
                    filePath: root.userFilePath
                    text: qsTr("Play\nMe")
                }
            }

            // Advanced Button
            Button {
                id: advancedButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 48
                flat: false

                contentItem: Text {
                    text: qsTr("Advanced")
                    font.pixelSize: 16
                    font.weight: 600
                    color: advancedButton.down ? Qt.darker(Theme.onPrimary(root.Material.theme), 1.1) : Theme.onPrimary(root.Material.theme)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                background: Rectangle {
                    radius: 24
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: advancedButton.hovered ? Qt.lighter(Theme.primary(root.Material.theme), 1.1) : Theme.primary(root.Material.theme)
                        }
                        GradientStop {
                            position: 1.0
                            color: advancedButton.hovered ? Theme.primary(root.Material.theme) : Qt.darker(Theme.primary(root.Material.theme), 1.2)
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.2)
                        blur: advancedButton.hovered ? 0.3 : 0.2
                        shadowVerticalOffset: advancedButton.hovered ? 6 : 4
                    }

                    scale: advancedButton.pressed ? 0.95 : (advancedButton.hovered ? 1.02 : 1.0)
                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutBack
                        }
                    }
                }

                onClicked: {
                    stackView.push("TemplatePage.qml", {
                        filePath: root.referenceFilePath
                    });
                }
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }
}
