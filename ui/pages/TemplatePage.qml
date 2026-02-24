import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8
import QtQuick.Layouts

import by.intontrainer.wavfile 1.0

import "../components"
import "../utils"

Page {
    id: root
    property string refFilePath: ""
    property string userFilePath: ""
    property bool showSettings: false

    property var refWavFileHandle: null
    property var userWavFileHandle: null
    property var loadedCuePoints: []
    property var loadedWaveData: []
    property var refPatternData: []
    property var refPitchData: []

    title: refFilePath.substring(refFilePath.lastIndexOf('/') + 1)

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

        function onSpecFftLengthChanged() {
            updateData();
        }
        function onSpecF0RefinementChanged() {
            updateData();
        }
        function onSpecUseLogScaleChanged() {
            refSpectrumGraph.useLogScale = window.settingsApi.specUseLogScale;
            userSpectrumGraph.useLogScale = window.settingsApi.specUseLogScale;
        }
        function onSpecColorSchemeChanged() {
            updateColorScheme();
        }
        function onCepstrNumOrderChanged() {
            updateData();
        }
        function onShowSpectrumChanged() {
            updateData();
        }
        function onShowCepstrumChanged() {
            updateData();
        }
        function onShowAmplitudeChanged() {
            updateData();
        }
        function onShowAmplitudeDerivativeChanged() {
            updateData();
        }
        function onAmplitudeWindowChanged() {
            updateData();
        }
        function onAmplitudeShiftChanged() {
            updateData();
        }
    }

    function updateColorScheme() {
        let scheme = window.settingsApi.specColorScheme;
        let colorSchemeStr = "viridis";
        if (scheme === 0)
            colorSchemeStr = "viridis";
        else if (scheme === 1)
            colorSchemeStr = "plasma";
        else if (scheme === 2)
            colorSchemeStr = "hot";
        else if (scheme === 3)
            colorSchemeStr = "cool";

        refSpectrumGraph.colorScheme = colorSchemeStr;
        refCepstrogramGraph.colorScheme = colorSchemeStr;

        userSpectrumGraph.colorScheme = colorSchemeStr;
        userCepstrogramGraph.colorScheme = colorSchemeStr;
    }

    function updateData() {
        updateRefData();
        updateUserData();
    }

    function updateUserData() {
        if (!userWavFileHandle)
            return;
        // Extract amplitude data
        Logger.debug("Extracting amplitude data");
        let ampData = wavFileApi.getAmplitude(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);
        userAmplitudeWaveFormGraph.waveData = [ampData];

        Logger.debug("Extracting amplitude derivative data");
        let ampDeriv = wavFileApi.getAmplitudeDerivative(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);
        userAmplitudeDerivWaveFormGraph.waveData = [ampDeriv];
        // Extract pitch data
        Logger.debug("Extracting pitch original data with algorithm: " + window.settingsApi.algorithm);
        let pitchOriginalData = wavFileApi.getPitch(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", "", "None", "None");
        Logger.debug("Pitch original data length: " + pitchOriginalData.length);
        userPitchWaveFormGraph.waveData = [pitchOriginalData];

        Logger.debug("Extracting pitch data with algorithm: " + window.settingsApi.algorithm);
        let pitchData = wavFileApi.getPitch(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);
        Logger.debug("Pitch data length: " + pitchData.length);
        userPitchProcessedWaveFormGraph.waveData = [pitchData];

        // Extract spectrum data
        Logger.debug("Extracting spectrum with FFT length: " + window.settingsApi.specFftLength);
        let specData = wavFileApi.getSpec(userWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Spectrum data frames: " + specData.length);

        // Pass spectrum data directly to the 2D graph
        userSpectrumGraph.spectrumData = specData;

        // Extract cepstrum data
        Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
        let cepstrData = wavFileApi.getCepstr(userWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.cepstrNumOrder, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Cepstrum data frames: " + cepstrData.length);
        userCepstrogramGraph.spectrumData = cepstrData;

        // Run DP comparison
        Logger.debug("Calculating DP...");
        let scaledPitch = wavFileApi.getSpecDP(refPatternData, cepstrData, pitchData, refPitchData.length);
        Logger.debug("DP result length: " + scaledPitch.length);

        Logger.debug("Calculating UMP...");
        let umpResult = wavFileApi.getUMP(scaledPitch, loadedCuePoints, 50, 100, 50, loadedWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);
        Logger.debug("UMP calculated with " + umpResult.cuePoints.length + " cue points");

        userUmpWaveFormGraph.waveData = umpResult.ump;
        userUmpWaveFormGraph.cuePoints = refUmpWaveFormGraph.cuePoints;
    }

    function updateRefData() {
        if (!refWavFileHandle)
            return;
        // Extract amplitude data
        Logger.debug("Extracting amplitude data");
        let ampData = wavFileApi.getAmplitude(refWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);
        refAmplitudeWaveFormGraph.waveData = [ampData];

        Logger.debug("Extracting amplitude derivative data");
        let ampDeriv = wavFileApi.getAmplitudeDerivative(refWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);
        refAmplitudeDerivWaveFormGraph.waveData = [ampDeriv];
        // Extract pitch data
        Logger.debug("Extracting pitch original data with algorithm: " + window.settingsApi.algorithm);
        let pitchOriginalData = wavFileApi.getPitch(refWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", "", "None", "None");
        Logger.debug("Pitch original data length: " + pitchOriginalData.length);
        refPitchWaveFormGraph.waveData = [pitchOriginalData];

        Logger.debug("Extracting pitch data with algorithm: " + window.settingsApi.algorithm);
        refPitchData = wavFileApi.getPitch(refWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);
        Logger.debug("Pitch data length: " + refPitchData.length);
        refPitchProcessedWaveFormGraph.waveData = [refPitchData];

        // Scale loadedCuePoints to match pitch data length
        let scaledCuePoints = loadedCuePoints.map(cp => {
            return {
                position: Math.round(cp.position * refPitchData.length / loadedWaveData.length),
                label: cp.label,
                length: Math.round(cp.length * refPitchData.length / loadedWaveData.length)
            };
        });
        refPitchProcessedWaveFormGraph.cuePoints = scaledCuePoints;
        refPitchWaveFormGraph.cuePoints = scaledCuePoints;

        // Calculate UMP
        Logger.debug("Calculating UMP...");
        let umpResult = wavFileApi.getUMP(refPitchData, loadedCuePoints, 50, 100, 50, loadedWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);
        Logger.debug("UMP calculated with " + umpResult.cuePoints.length + " cue points");
        refUmpWaveFormGraph.waveData = umpResult.ump;
        refUmpWaveFormGraph.cuePoints = umpResult.cuePoints;

        // Extract spectrum data
        Logger.debug("Extracting spectrum with FFT length: " + window.settingsApi.specFftLength);
        let specData = wavFileApi.getSpec(refWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Spectrum data frames: " + specData.length);

        // Pass spectrum data directly to the 2D graph
        refSpectrumGraph.spectrumData = specData;

        // Extract cepstrum data
        Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
        refPatternData = wavFileApi.getCepstr(refWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.cepstrNumOrder, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Cepstrum data frames: " + refPatternData.length);
        refCepstrogramGraph.spectrumData = refPatternData;
    }

    Component.onCompleted: {
        Logger.info("TemplatePage initialization started");

        if (refFilePath) {
            Logger.debug("Opening reference WAV file: " + refFilePath);
            refWavFileHandle = wavFileApi.openWavFile(refFilePath);

            Logger.debug("Extracting cue points...");
            loadedCuePoints = wavFileApi.getCuePoints(refWavFileHandle);
            Logger.debug("Found " + loadedCuePoints.length + " cue points");

            Logger.debug("Extracting wave data...");
            loadedWaveData = wavFileApi.getWaveData(refWavFileHandle);
            Logger.debug("Wave data length: " + loadedWaveData.length);

            refWaveFormGraph.waveData = loadedWaveData;
            refWaveFormGraph.cuePoints = loadedCuePoints;
        }

        if (userFilePath) {
            Logger.debug("Opening user WAV file: " + userFilePath);
            userWavFileHandle = wavFileApi.openWavFile(userFilePath);
            let userWaveData = wavFileApi.getWaveData(userWavFileHandle);
            Logger.debug("User wave data length: " + userWaveData.length);
            userWaveFormGraph.waveData = userWaveData;
        }

        updateData();

        // Initialize spectrum visualization settings
        refSpectrumGraph.useLogScale = window.settingsApi.specUseLogScale;
        refCepstrogramGraph.useLogScale = false;

        userSpectrumGraph.useLogScale = window.settingsApi.specUseLogScale;
        userCepstrogramGraph.useLogScale = false;
        updateColorScheme();

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

                    Text {
                        text: qsTr("Waveforms")
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    Text {
                        text: qsTr("Reference")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: refWaveFormGraph
                        width: parent.width
                        height: 300
                    }

                    PlayButton {
                        id: refPlayButton
                        width: 32
                        height: 32
                        file: refFilePath
                        showLabel: true
                    }

                    Text {
                        text: qsTr("User")
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: userWaveFormGraph
                        width: parent.width
                        height: 300
                    }

                    PlayButton {
                        id: userPlayButton
                        width: 32
                        height: 32
                        file: userFilePath
                        showLabel: true
                    }

                    Column {
                        visible: window.settingsApi.showSpectrum
                        width: parent.width
                        spacing: 10

                        Text {
                            text: qsTr("Spectrum")
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Text {
                            text: qsTr("Reference")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Spectrogram2DGraph {
                            id: refSpectrumGraph
                            width: parent.width
                            height: 400
                        }

                        Text {
                            text: qsTr("User")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Spectrogram2DGraph {
                            id: userSpectrumGraph
                            width: parent.width
                            height: 400
                        }
                    }

                    Column {
                        visible: window.settingsApi.showCepstrum
                        width: parent.width
                        spacing: 10

                        Text {
                            text: qsTr("Cepstrum")
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Text {
                            text: qsTr("Reference")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Spectrogram2DGraph {
                            id: refCepstrogramGraph
                            width: parent.width
                            height: 400
                        }

                        Text {
                            text: qsTr("User")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Spectrogram2DGraph {
                            id: userCepstrogramGraph
                            width: parent.width
                            height: 400
                        }
                    }

                    // Amplitude graphs
                    Column {
                        visible: window.settingsApi.showAmplitude
                        width: parent.width
                        spacing: 10

                        Text {
                            text: qsTr("Amplitude")
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Text {
                            text: qsTr("Reference")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        WaveFormGraph {
                            id: refAmplitudeWaveFormGraph
                            width: parent.width - 80
                            height: 200
                        }

                        Text {
                            text: qsTr("User")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        WaveFormGraph {
                            id: userAmplitudeWaveFormGraph
                            width: parent.width - 80
                            height: 200
                        }
                    }

                    Column {
                        visible: window.settingsApi.showAmplitudeDerivative
                        width: parent.width
                        spacing: 10

                        Text {
                            text: qsTr("Amplitude Derivative")
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        Text {
                            text: qsTr("Reference")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        WaveFormGraph {
                            id: refAmplitudeDerivWaveFormGraph
                            width: parent.width - 80
                            height: 200
                        }

                        Text {
                            text: qsTr("User")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface(root.Material.theme)
                        }

                        WaveFormGraph {
                            id: userAmplitudeDerivWaveFormGraph
                            width: parent.width - 80
                            height: 200
                        }
                    }

                    Text {
                        text: qsTr("Pitch (F0)")
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    Text {
                        text: qsTr("Reference")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: refPitchWaveFormGraph
                        width: parent.width - 80
                        height: 200
                    }

                    Text {
                        text: qsTr("User")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: userPitchWaveFormGraph
                        width: parent.width - 80
                        height: 200
                    }

                    Text {
                        text: qsTr("Processed Pitch (F0)")
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    Text {
                        text: qsTr("Reference")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: refPitchProcessedWaveFormGraph
                        width: parent.width - 80
                        height: 200
                    }

                    Text {
                        text: qsTr("User")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: userPitchProcessedWaveFormGraph
                        width: parent.width - 80
                        height: 200
                    }

                    Text {
                        text: qsTr("UMP")
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    Text {
                        text: qsTr("Reference")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: refUmpWaveFormGraph
                        width: parent.width - 80
                        height: 200
                    }

                    Text {
                        text: qsTr("User")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.onSurface(root.Material.theme)
                    }

                    WaveFormGraph {
                        id: userUmpWaveFormGraph
                        width: parent.width - 80
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
