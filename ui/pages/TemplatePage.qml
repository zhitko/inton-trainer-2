import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8
import QtQuick.Layouts

import "../components"
import "../utils"

import by.intontrainer.wavfile 1.0

Page {
    id: root

    // Cache settingsApi with null safety
    readonly property var settingsApi: ApplicationWindow.window ? ApplicationWindow.settingsApi : null

    property var loadedCuePoints: []
    property var refWaveData: []
    property var userWaveData: []
    property var refAmplitudeData: []
    property var refAmplitudeDerivData: []
    property string refFilePath: ""
    property var logPitchData: []
    property var refLogPitchData: []
    property var refPatternData: []
    property var refPitchData: []
    property var refWavFileHandle: null
    property var refSpecData: []
    property var refPitchDerivData: []
    property bool showSettings: false
    property string userFilePath: ""
    property var userWavFileHandle: null
    property double dpMinFinalCost: 0.0
    property var dpSignalStreamDistances: []

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

    function updateRefData() {
        if (!refWavFileHandle)
            return;
        // Extract amplitude data
        Logger.debug("Extracting amplitude data");
        let ampData = wavFileApi.getAmplitude(refWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);
        refAmplitudeWaveFormGraph.waveData = [ampData];
        root.refAmplitudeData = ampData;

        Logger.debug("Extracting amplitude derivative data");
        let ampDeriv = wavFileApi.getAmplitudeDerivative(refWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);
        refAmplitudeDerivWaveFormGraph.waveData = [ampDeriv];
        root.refAmplitudeDerivData = ampDeriv;
        // Extract pitch data
        Logger.debug("Extracting pitch original data with algorithm: " + window.settingsApi.algorithm);
        let pitchOriginalData = wavFileApi.getPitch(refWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", "", "None", "None");
        Logger.debug("Pitch original data length: " + pitchOriginalData.length);
        refPitchWaveFormGraph.waveData = [pitchOriginalData];

        Logger.debug("Extracting pitch data with algorithm: " + window.settingsApi.algorithm);
        refPitchData = wavFileApi.getPitch(refWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty, true, window.settingsApi.useOnlyN);
        Logger.debug("Pitch data length: " + refPitchData.length);
        refPitchProcessedWaveFormGraph.waveData = [refPitchData];

        Logger.debug("Extracting log pitch data with algorithm: " + window.settingsApi.algorithm);
        refLogPitchData = wavFileApi.getPitch(refWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0", "None", "None", 0, 0, 0, window.settingsApi.useOnlyN);
        Logger.debug("Log pitch data length: " + refLogPitchData.length);
        refLogPitchWaveFormGraph.waveData = [refLogPitchData];

        // Scale loadedCuePoints to match pitch data length
        let scaledCuePoints = loadedCuePoints.map(cp => {
            return {
                position: Math.round(cp.position * refPitchData.length / refWaveData.length),
                label: cp.label,
                length: Math.round(cp.length * refPitchData.length / refWaveData.length)
            };
        });
        refPitchProcessedWaveFormGraph.cuePoints = scaledCuePoints;
        refPitchWaveFormGraph.cuePoints = scaledCuePoints;

        // Calculate UMP
        Logger.debug("Calculating UMP...");
        let umpResult = wavFileApi.getUMP(refPitchData, loadedCuePoints, 50, 100, 50, refWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.umpSmoothing], window.settingsApi.umpSmoothingWindowSize, window.settingsApi.umpGaussianSmoothingSigma, window.settingsApi.umpSplineSmoothingPenalty);
        Logger.debug("UMP calculated with " + umpResult.cuePoints.length + " cue points");
        refUmpWaveFormGraph.waveData = umpResult.ump;
        refUmpWaveFormGraph.cuePoints = umpResult.cuePoints;

        // Extract spectrum data
        Logger.debug("Extracting spectrum with FFT length: " + window.settingsApi.specFftLength);
        let specData = wavFileApi.getSpec(refWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Spectrum data frames: " + specData.length);
        root.refSpecData = specData;

        // Pass spectrum data directly to the 2D graph
        refSpectrumGraph.spectrumData = specData;

        // Extract cepstrum data
        Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
        refPatternData = wavFileApi.getCepstr(refWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.cepstrNumOrder, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Cepstrum data frames: " + refPatternData.length);
        refCepstrogramGraph.spectrumData = refPatternData;

        // Extract pitch derivative data
        Logger.debug("Extracting pitch derivative data");
        root.refPitchDerivData = wavFileApi.getPitchDerivative(refWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0");
        Logger.debug("Pitch derivative data length: " + root.refPitchDerivData.length);
    }

    function updateUserData() {
        if (!userWavFileHandle)
            return;
        // Extract amplitude data
        Logger.debug("Extracting amplitude data");
        let ampData = wavFileApi.getAmplitude(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);
        userAmplitudeWaveFormGraph.waveData = [ampData];

        Logger.debug("Extracting amplitude derivative data");
        let ampDeriv = wavFileApi.getAmplitudeDerivative(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);
        userAmplitudeDerivWaveFormGraph.waveData = [ampDeriv];
        // Extract pitch data
        Logger.debug("Extracting pitch original data with algorithm: " + window.settingsApi.algorithm);
        let pitchOriginalData = wavFileApi.getPitch(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", "", "None", "None");
        Logger.debug("Pitch original data length: " + pitchOriginalData.length);
        userPitchWaveFormGraph.waveData = [pitchOriginalData];

        Logger.debug("Extracting pitch data with algorithm: " + window.settingsApi.algorithm);
        let pitchData = wavFileApi.getPitch(
            userWavFileHandle, 
            window.settingsApi.algorithm, 
            window.settingsApi.frameShift, 
            window.settingsApi.sampleRate, 
            window.settingsApi.minF0, 
            window.settingsApi.maxF0, 
            window.settingsApi.voicingThreshold, 
            "PITCH", 
            window.settingsApi.pitchNormalization, 
            ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], 
            ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], 
            window.settingsApi.pitchSmoothingWindowSize, 
            window.settingsApi.pitchGaussianSmoothingSigma, 
            window.settingsApi.pitchSplineSmoothingPenalty
        );
        Logger.debug("Pitch data length: " + pitchData.length);
        userPitchProcessedWaveFormGraph.waveData = [pitchData];

        Logger.debug("Extracting log pitch data with algorithm: " + window.settingsApi.algorithm);
        logPitchData = wavFileApi.getPitch(
            userWavFileHandle, 
            window.settingsApi.algorithm, 
            window.settingsApi.frameShift, 
            window.settingsApi.sampleRate, 
            window.settingsApi.minF0, 
            window.settingsApi.maxF0, 
            window.settingsApi.voicingThreshold, 
            "LOG_F0", 
            "None", 
            "None", 
            "None", 
            0, 
            0, 
            0
        );
        Logger.debug("Log pitch data length: " + logPitchData.length);
        userLogPitchWaveFormGraph.waveData = [logPitchData];

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

        // Extract pitch derivative data
        Logger.debug("Extracting pitch derivative data");
        let pitchDerivData = wavFileApi.getPitchDerivative(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0");
        Logger.debug("Pitch derivative data length: " + pitchDerivData.length);

        // Run DP comparison
        Logger.debug("Calculating DP...");
        // Scale loadedCuePoints to match user pitch data length
        let scaledLoadedCuePoints = loadedCuePoints.map(cp => {
            return {
                position: Math.round(cp.position * refPitchData.length / refWaveData.length),
                label: cp.label,
                length: Math.round(cp.length * refPitchData.length / refWaveData.length)
            };
        });

        let dpResult = wavFileApi.getDP(root.refAmplitudeData, root.refAmplitudeDerivData, root.refLogPitchData, root.refLogPitchData, root.refPitchDerivData, root.refSpecData, root.refPatternData, ampData, ampDeriv, logPitchData, logPitchData, pitchDerivData, specData, cepstrData, pitchData, scaledLoadedCuePoints);
        let scaledPitch = dpResult.pitch;
        Logger.debug("DP result pitch length: " + scaledPitch.length);

        root.dpMinFinalCost = dpResult.minFinalCost;
        root.dpSignalStreamDistances = dpResult.signalStreamDistances;
        dtwSignalStreamGraph.waveData = [dpResult.signalStreamDistances];
        Logger.debug("DP minFinalCost: " + root.dpMinFinalCost + ", signalStreamDistances length: " + root.dpSignalStreamDistances.length);

        Logger.debug("Calculating UMP...");
        let umpResult = wavFileApi.getUMP(scaledPitch, loadedCuePoints, 50, 100, 50, refWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.umpSmoothing], window.settingsApi.umpSmoothingWindowSize, window.settingsApi.umpGaussianSmoothingSigma, window.settingsApi.umpSplineSmoothingPenalty);
        Logger.debug("UMP calculated with " + umpResult.cuePoints.length + " cue points");

        userUmpWaveFormGraph.waveData = umpResult.ump;
        userUmpWaveFormGraph.cuePoints = umpResult.cuePoints;

        // Scale dpResult.cuePoints to match userWaveFormGraph.waveData length
        let scaledCuePoints = dpResult.cuePoints.map(cp => {
            return {
                position: Math.round(cp.position * userWaveData.length / logPitchData.length),
                label: cp.label,
                length: Math.round(cp.length * userWaveData.length / logPitchData.length)
            };
        });
        userWaveFormGraph.cuePoints = scaledCuePoints;

        // Scale dpResult.cuePoints to match userPitchProcessedWaveFormGraph.waveData length
        let processedScaledCuePoints = dpResult.cuePoints.map(cp => {
            return {
                position: Math.round(cp.position * pitchData.length / logPitchData.length),
                label: cp.label,
                length: Math.round(cp.length * pitchData.length / logPitchData.length)
            };
        });
        userPitchWaveFormGraph.cuePoints = processedScaledCuePoints;
        userPitchProcessedWaveFormGraph.cuePoints = processedScaledCuePoints;
    }

    title: refFilePath.substring(refFilePath.lastIndexOf('/') + 1)

    Component.onCompleted: {
        Logger.info("TemplatePage initialization started");

        if (refFilePath) {
            Logger.debug("Opening reference WAV file: " + refFilePath);
            refWavFileHandle = wavFileApi.openWavFile(refFilePath);

            Logger.debug("Extracting cue points...");
            loadedCuePoints = wavFileApi.getCuePoints(refWavFileHandle);
            Logger.debug("Found " + loadedCuePoints.length + " cue points");

            Logger.debug("Extracting wave data...");
            refWaveData = wavFileApi.getWaveData(refWavFileHandle);
            Logger.debug("Wave data length: " + refWaveData.length);

            refWaveFormGraph.waveData = refWaveData;
            refWaveFormGraph.cuePoints = loadedCuePoints;
        }

        if (userFilePath) {
            Logger.debug("Opening user WAV file: " + userFilePath);
            userWavFileHandle = wavFileApi.openWavFile(userFilePath);
            userWaveData = wavFileApi.getWaveData(userWavFileHandle);
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

    WavFileApi {
        id: wavFileApi
    }

    Connections {
        target: window.settingsApi

        function onSettingsChanged() {
            Logger.debug("TemplatePage onSettingsChanged: refreshing graphs");
            root.updateData();
            root.updateColorScheme();
            refSpectrumGraph.useLogScale = window.settingsApi.specUseLogScale;
            userSpectrumGraph.useLogScale = window.settingsApi.specUseLogScale;
        }
    }



    Button {
        anchors.right: parent.right
        anchors.top: parent.top
        text: root.showSettings ? qsTr("Hide Settings") : qsTr("Show Settings")
        z: 99

        onClicked: root.showSettings = !root.showSettings
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: availableWidth

                Column {
                    spacing: 10
                    width: parent.width

                    Text {
                        color: Theme.onSurface(root.Material.theme)
                        font.bold: true
                        font.pixelSize: 16
                        text: qsTr("Reference waveform") + " - " + root.refFilePath.substring(root.refFilePath.lastIndexOf('/') + 1)
                    }

                    WaveFormGraph {
                        id: refWaveFormGraph

                        height: 300
                        width: parent.width - 80
                    }

                    PlayButton {
                        id: refPlayButton

                        file: refFilePath
                        height: 32
                        showLabel: true
                        width: 32
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showF0
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Reference Pitch (F0)")
                        }

                        WaveFormGraph {
                            id: refPitchWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showProcessedPitch
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Reference Processed Pitch (F0)")
                        }

                        WaveFormGraph {
                            id: refPitchProcessedWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showLogPitch
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Reference Log Pitch (LOG_F0)")
                        }

                        WaveFormGraph {
                            id: refLogPitchWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Text {
                        color: Theme.onSurface(root.Material.theme)
                        font.bold: true
                        font.pixelSize: 16
                        text: qsTr("Reference UMP")
                    }

                    WaveFormGraph {
                        id: refUmpWaveFormGraph

                        height: 200
                        width: parent.width - 80
                        lineWidth: 5
                    }

                    Text {
                        color: Theme.onSurface(root.Material.theme)
                        font.bold: true
                        font.pixelSize: 16
                        text: qsTr("User waveform") + " - " + root.userFilePath.substring(root.userFilePath.lastIndexOf('/') + 1)
                    }

                    WaveFormGraph {
                        id: userWaveFormGraph

                        height: 300
                        width: parent.width - 80
                    }

                    PlayButton {
                        id: userPlayButton

                        file: userFilePath
                        height: 32
                        showLabel: true
                        width: 32
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showF0
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("User Pitch (F0)")
                        }

                        WaveFormGraph {
                            id: userPitchWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showProcessedPitch
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("User Processed Pitch (F0)")
                        }

                        WaveFormGraph {
                            id: userPitchProcessedWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showLogPitch
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("User Log Pitch (LOG_F0)")
                        }

                        WaveFormGraph {
                            id: userLogPitchWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Text {
                        color: Theme.onSurface(root.Material.theme)
                        font.bold: true
                        font.pixelSize: 16
                        text: qsTr("User UMP")
                    }

                    WaveFormGraph {
                        id: userUmpWaveFormGraph

                        height: 200
                        width: parent.width - 80
                        lineWidth: 5
                    }

                    // Amplitude graphs
                    Column {
                        spacing: 10
                        visible: window.settingsApi.showAmplitude
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Amplitude")
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("Reference")
                        }

                        WaveFormGraph {
                            id: refAmplitudeWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("User")
                        }

                        WaveFormGraph {
                            id: userAmplitudeWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showAmplitudeDerivative
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Amplitude Derivative")
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("Reference")
                        }

                        WaveFormGraph {
                            id: refAmplitudeDerivWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("User")
                        }

                        WaveFormGraph {
                            id: userAmplitudeDerivWaveFormGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showSpectrum
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Spectrum")
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("Reference")
                        }

                        Spectrogram2DGraph {
                            id: refSpectrumGraph

                            height: 400
                            width: parent.width
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("User")
                        }

                        Spectrogram2DGraph {
                            id: userSpectrumGraph

                            height: 400
                            width: parent.width
                        }
                    }

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showCepstrum
                        width: parent.width

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Cepstrum")
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("Reference")
                        }

                        Spectrogram2DGraph {
                            id: refCepstrogramGraph

                            height: 400
                            width: parent.width
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("User")
                        }

                        Spectrogram2DGraph {
                            id: userCepstrogramGraph

                            height: 400
                            width: parent.width
                        }
                    }

                    // DTW Alignment section
                    Column {
                        spacing: 10
                        width: parent.width
                        visible: settingsApi ? window.settingsApi.showDtwAlignment : true

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("DTW Distances")
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.pixelSize: 14
                            text: qsTr("Best alignment cost: ") + root.dpMinFinalCost.toFixed(6)
                        }

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 14
                            text: qsTr("Signal Distances")
                        }

                        WaveFormGraph {
                            id: dtwSignalStreamGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Theme.outlineVariant(root.Material.theme)
            visible: root.showSettings
        }

        SettingsPage {
            Layout.fillHeight: true
            Layout.preferredWidth: 430
            visible: root.showSettings

            background: Rectangle {
                color: Theme.surface(root.Material.theme)
            }
        }
    }
}
