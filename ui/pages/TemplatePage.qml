import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8
import QtQuick.Layouts

import by.intontrainer.wavfile 1.0

import "../components"
import "../utils"

Page {
    id: root
    property string filePath: ""
    property bool showSettings: true

    property var wavFileHandle: null
    property var loadedCuePoints: []
    property var loadedWaveData: []

    title: filePath.substring(filePath.lastIndexOf('/') + 1)

    WavFileApi {
        id: wavFileApi
    }

    Connections {
        target: window.settingsApi
        function onAlgorithmChanged() {
            updateData();
        }
        function onFrameShiftChanged() {
            updateData();
        }
        function onSampleRateChanged() {
            updateData();
        }
        function onMinF0Changed() {
            updateData();
        }
        function onMaxF0Changed() {
            updateData();
        }
        function onVoicingThresholdChanged() {
            updateData();
        }
        function onPitchNormalizationChanged() {
            updateData();
        }
        function onPitchInterpolationTypeChanged() {
            updateData();
        }
        function onPitchSmoothingChanged() {
            updateData();
        }
        function onPitchSmoothingWindowSizeChanged() {
            updateData();
        }
        function onPitchGaussianSmoothingSigmaChanged() {
            updateData();
        }

        function onPitchSplineSmoothingPenaltyChanged() {
            updateData();
        }
    }

    function updateData() {
        if (!wavFileHandle)
            return;

        // Extract pitch data
        Logger.debug("Extracting pitch original data with algorithm: " + window.settingsApi.algorithm);
        let pitchOriginalData = wavFileApi.getPitch(wavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", "", "None", "None");
        Logger.debug("Pitch original data length: " + pitchOriginalData.length);
        pitchWaveFormGraph.waveData = [pitchOriginalData];

        Logger.debug("Extracting pitch data with algorithm: " + window.settingsApi.algorithm);
        let pitchData = wavFileApi.getPitch(wavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);
        Logger.debug("Pitch data length: " + pitchData.length);
        pitchProcessedWaveFormGraph.waveData = [pitchData];

        // Calculate UMP
        Logger.debug("Calculating UMP...");
        let umpResult = wavFileApi.getUMP(pitchData, loadedCuePoints, 50, 100, 50, loadedWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType]);
        Logger.debug("UMP calculated with " + umpResult.cuePoints.length + " cue points");
        umpWaveFormGraph.waveData = umpResult.ump;
        umpWaveFormGraph.cuePoints = umpResult.cuePoints;
    }

    Component.onCompleted: {
        Logger.info("TemplatePage loaded for file: " + filePath);

        Logger.debug("Opening WAV file...");
        wavFileHandle = wavFileApi.openWavFile(filePath);

        Logger.debug("Extracting cue points...");
        loadedCuePoints = wavFileApi.getCuePoints(wavFileHandle);
        Logger.debug("Found " + loadedCuePoints.length + " cue points");

        Logger.debug("Extracting wave data...");
        loadedWaveData = wavFileApi.getWaveData(wavFileHandle);
        Logger.debug("Wave data length: " + loadedWaveData.length);

        waveFormGraph.waveData = loadedWaveData;
        waveFormGraph.cuePoints = loadedCuePoints;

        updateData();

        Logger.info("TemplatePage initialization complete");
    }

    Button {
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.showSettings ? qsTr("Hide Settings") : qsTr("Show Settings")
        onClicked: root.showSettings = !root.showSettings
        z: 99
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: availableWidth

                Column {
                    width: parent.width
                    spacing: 10

                    WaveFormGraph {
                        id: waveFormGraph
                        width: parent.width
                        height: 300
                    }

                    PlayButton {
                        id: playButton
                        width: 32
                        height: 32
                        file: filePath
                        showLabel: true
                    }

                    Text {
                        text: qsTr("Pitch (F0)")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: pitchWaveFormGraph
                        width: parent.width
                        height: 200
                    }

                    WaveFormGraph {
                        id: pitchProcessedWaveFormGraph
                        width: parent.width
                        height: 200
                    }

                    Text {
                        text: qsTr("UMP")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: umpWaveFormGraph
                        width: parent.width
                        height: 200
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Theme.outlineVariant(root.Material.theme)
            visible: root.showSettings
        }

        SettingsPage {
            visible: root.showSettings
            Layout.preferredWidth: 400
            Layout.fillHeight: true
            background: Rectangle {
                color: Theme.surface(root.Material.theme)
            }
        }
    }
}
