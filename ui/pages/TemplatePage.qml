import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8
import QtQuick.Layouts

import "../components"
import "../utils"

import by.intontrainer.wavfile 1.0

Page {
    id: root

    // Shorthand computed accessors for repeated index→string lookups
    readonly property string pitchInterpolationName: window.settingsApi ? ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType] : "None"
    readonly property string pitchSmoothingName:     window.settingsApi ? ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing]    : "None"
    readonly property string amplitudeSmoothingName:  window.settingsApi ? ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing]           : "None"
    readonly property string umpSmoothingName:        window.settingsApi ? ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.umpSmoothing]       : "None"

    // ── Page state ──────────────────────────────────────────────────────────
    property bool   showSettings:    false
    property string referenceFilePath: ""
    property string userFilePath:    ""

    // ── WAV file handles ────────────────────────────────────────────────────
    property var referenceWavFileHandle: null
    property var userWavFileHandle:      null

    // ── Reference audio data ────────────────────────────────────────────────
    property var referenceCuePoints:       []
    property var referenceWaveData:        []
    property var referenceAmplitudeData:   []
    property var referenceAmplitudeDerivData: []
    property var referencePitchData:       []
    property var referenceLogPitchData:    []
    property var referencePitchDerivData:  []
    property var referenceSpecData:        []
    property var referenceCepstrData:      []

    // ── User audio data ─────────────────────────────────────────────────────
    property var userWaveData:       []
    property var userLogPitchData:   []

    // ── DP / alignment results ──────────────────────────────────────────────
    property double dpMinFinalCost:        0.0
    property var    dpSignalStreamDistances: []
    property var    dpTemplateData:        []
    property var    dpSignalData:          []

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
        if (!referenceWavFileHandle)
            return;

        // ── Amplitude ─────────────────────────────────────────────────────────
        // getDP uses amplitude only when dpUseAmplitude / dpUseAmplitudeDerivative
        // is enabled, so we skip the extraction entirely when the flag is off.
        if (settingsApi.dpUseAmplitude || settingsApi.showAmplitude) {
            Logger.debug("Extracting reference amplitude");
            let refAmplitudeData = wavFileApi.getAmplitude(
                referenceWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
            referenceAmplitudeData = refAmplitudeData;
            refAmplitudeWaveFormGraph.waveData = [refAmplitudeData];
        } else {
            referenceAmplitudeData = [];
        }

        if (settingsApi.dpUseAmplitudeDerivative || settingsApi.showAmplitudeDerivative) {
            let refAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(
                referenceWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
            referenceAmplitudeDerivData = refAmplitudeDerivData;
            refAmplitudeDerivWaveFormGraph.waveData = [refAmplitudeDerivData];
        } else {
            referenceAmplitudeDerivData = [];
        }

        // ── Pitch ─────────────────────────────────────────────────────────────
        // Raw (unprocessed) pitch — display-only, skip when F0 graph is hidden.
        if (settingsApi.showF0) {
            Logger.debug("Extracting reference raw pitch");
            let refPitchOriginalData = wavFileApi.getPitch(
                referenceWavFileHandle,
                window.settingsApi.algorithm,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                "PITCH", "", "None", "None"
            );
            Logger.debug("Raw pitch length: " + refPitchOriginalData.length);
            refPitchWaveFormGraph.waveData = [refPitchOriginalData];
        }

        // Processed pitch — needed by getDP when dpUsePitch is on, and always
        // needed for UMP (display) and as pitchToTransform argument for getDP.
        // Always compute so scaled cue points and UMP can work correctly.
        Logger.debug("Extracting reference processed pitch");
        referencePitchData = wavFileApi.getPitch(
            referenceWavFileHandle,
            window.settingsApi.algorithm,
            window.settingsApi.frameShift,
            window.settingsApi.sampleRate,
            window.settingsApi.minF0,
            window.settingsApi.maxF0,
            window.settingsApi.voicingThreshold,
            "PITCH",
            window.settingsApi.pitchNormalization,
            pitchInterpolationName,
            pitchSmoothingName,
            window.settingsApi.pitchSmoothingWindowSize,
            window.settingsApi.pitchGaussianSmoothingSigma,
            window.settingsApi.pitchSplineSmoothingPenalty,
            true,
            window.settingsApi.useOnlyN
        );
        Logger.debug("Processed pitch length: " + referencePitchData.length);
        refPitchProcessedWaveFormGraph.waveData = [referencePitchData];

        // Log pitch — only needed when dpUsePitchLog is active.
        if (settingsApi.dpUsePitchLog || settingsApi.showLogPitch) {
            Logger.debug("Extracting reference log pitch");
            referenceLogPitchData = wavFileApi.getPitch(
                referenceWavFileHandle,
                window.settingsApi.algorithm,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                "LOG_F0", "None", "None", 0, 0, 0,
                window.settingsApi.useOnlyN
            );
            Logger.debug("Log pitch length: " + referenceLogPitchData.length);
            refLogPitchWaveFormGraph.waveData = [referenceLogPitchData];
        } else {
            referenceLogPitchData = [];
        }

        // Pitch derivative — only needed when dpUsePitchDerivative is active.
        if (settingsApi.dpUsePitchDerivative || settingsApi.showPitchDerivative) {
            Logger.debug("Extracting reference pitch derivative");
            referencePitchDerivData = wavFileApi.getPitchDerivative(
                referenceWavFileHandle,
                window.settingsApi.algorithm,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                "LOG_F0"
            );
            Logger.debug("Pitch derivative length: " + referencePitchDerivData.length);
        } else {
            referencePitchDerivData = [];
        }

        // ── Cue points scaled to pitch frame indices ───────────────────────────
        if ((settingsApi.showF0 || settingsApi.showProcessedPitch) && referencePitchData.length > 0) {
            let scaledCuePoints = referenceCuePoints.map(cp => ({
                position: Math.round(cp.position * referencePitchData.length / referenceWaveData.length),
                label:    cp.label,
                length:   Math.round(cp.length   * referencePitchData.length / referenceWaveData.length)
            }));
            refPitchProcessedWaveFormGraph.cuePoints = scaledCuePoints;
            refPitchWaveFormGraph.cuePoints = scaledCuePoints;
        }

        // ── UMP — display-only, skip when hidden ──────────────────────────────
        if (settingsApi.showUMP && referencePitchData.length > 0) {
            Logger.debug("Calculating reference UMP");
            let refUmpResult = wavFileApi.getUMP(
                referencePitchData,
                referenceCuePoints,
                50, 100, 50,
                referenceWaveData.length,
                pitchInterpolationName,
                umpSmoothingName,
                window.settingsApi.umpSmoothingWindowSize,
                window.settingsApi.umpGaussianSmoothingSigma,
                window.settingsApi.umpSplineSmoothingPenalty
            );
            Logger.debug("UMP cue points: " + refUmpResult.cuePoints.length);
            refUmpWaveFormGraph.waveData  = refUmpResult.ump;
            refUmpWaveFormGraph.cuePoints = refUmpResult.cuePoints;
        }

        // ── Spectrum / Cepstrum ────────────────────────────────────────────────
        // Only computed when getDP will actually use them.
        if (settingsApi.dpUseSpectrum || settingsApi.showSpectrum) {
            Logger.debug("Extracting reference spectrum (FFT: " + window.settingsApi.specFftLength + ")");
            let refSpecData = wavFileApi.getSpec(
                referenceWavFileHandle,
                window.settingsApi.specFftLength,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.algorithm,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                window.settingsApi.specF0Refinement
            );
            Logger.debug("Spectrum frames: " + refSpecData.length);
            referenceSpecData = refSpecData;
            refSpectrumGraph.spectrumData = refSpecData;
        } else {
            referenceSpecData = [];
        }

        if (settingsApi.dpUseCepstrum || settingsApi.showCepstrum) {
            Logger.debug("Extracting reference cepstrum (order: " + window.settingsApi.cepstrNumOrder + ")");
            referenceCepstrData = wavFileApi.getCepstr(
                referenceWavFileHandle,
                window.settingsApi.specFftLength,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.cepstrNumOrder,
                window.settingsApi.algorithm,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                window.settingsApi.specF0Refinement
            );
            Logger.debug("Cepstrum frames: " + referenceCepstrData.length);
            refCepstrogramGraph.spectrumData = referenceCepstrData;
        } else {
            referenceCepstrData = [];
        }
    }

    function updateUserData() {
        if (!userWavFileHandle || !referenceWavFileHandle)
            return;

        // ── Amplitude ── only extracted when getDP will use it ─────────────────
        let userAmplitudeData = [];
        if (settingsApi.dpUseAmplitude || settingsApi.showAmplitude) {
            Logger.debug("Extracting user amplitude");
            userAmplitudeData = wavFileApi.getAmplitude(
                userWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
            userAmplitudeWaveFormGraph.waveData = [userAmplitudeData];
        }

        let userAmplitudeDerivData = [];
        if (settingsApi.dpUseAmplitudeDerivative || settingsApi.showAmplitudeDerivative) {
            userAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(
                userWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
            userAmplitudeDerivWaveFormGraph.waveData = [userAmplitudeDerivData];
        }

        // ── Pitch ── raw display-only; processed+log+deriv guarded by dpUse flags
        if (settingsApi.showF0) {
            Logger.debug("Extracting user raw pitch");
            let userPitchOriginalData = wavFileApi.getPitch(
                userWavFileHandle,
                window.settingsApi.algorithm,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                "PITCH", "", "None", "None"
            );
            Logger.debug("User raw pitch length: " + userPitchOriginalData.length);
            userPitchWaveFormGraph.waveData = [userPitchOriginalData];
        }

        // Processed pitch: needed by getDP (dpUsePitch) AND as pitchToTransform
        // argument. Also needed for display and UMP. Always compute when any of
        // those consumers are active.
        let userPitchData = [];
        Logger.debug("Extracting user processed pitch");
        userPitchData = wavFileApi.getPitch(
            userWavFileHandle,
            window.settingsApi.algorithm,
            window.settingsApi.frameShift,
            window.settingsApi.sampleRate,
            window.settingsApi.minF0,
            window.settingsApi.maxF0,
            window.settingsApi.voicingThreshold,
            "PITCH",
            window.settingsApi.pitchNormalization,
            pitchInterpolationName,
            pitchSmoothingName,
            window.settingsApi.pitchSmoothingWindowSize,
            window.settingsApi.pitchGaussianSmoothingSigma,
            window.settingsApi.pitchSplineSmoothingPenalty
        );
        Logger.debug("User processed pitch length: " + userPitchData.length);
        userPitchProcessedWaveFormGraph.waveData = [userPitchData];

        if (settingsApi.dpUsePitchLog || settingsApi.showLogPitch) {
            Logger.debug("Extracting user log pitch");
            userLogPitchData = wavFileApi.getPitch(
                userWavFileHandle,
                window.settingsApi.algorithm,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                "LOG_F0", "None", "None", "None", 0, 0, 0
            );
            Logger.debug("User log pitch length: " + userLogPitchData.length);
            userLogPitchWaveFormGraph.waveData = [userLogPitchData];
        } else {
            userLogPitchData = [];
        }

        // ── Spectrum ── only when getDP will consume it ─────────────────────────
        let userSpecData = [];
        if (settingsApi.dpUseSpectrum || settingsApi.showSpectrum) {
            Logger.debug("Extracting user spectrum (FFT: " + window.settingsApi.specFftLength + ")");
            userSpecData = wavFileApi.getSpec(
                userWavFileHandle,
                window.settingsApi.specFftLength,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.algorithm,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                window.settingsApi.specF0Refinement
            );
            Logger.debug("User spectrum frames: " + userSpecData.length);
            userSpectrumGraph.spectrumData = userSpecData;
        }

        // ── Cepstrum ── only when getDP will consume it ─────────────────────────
        let userCepstrData = [];
        if (settingsApi.dpUseCepstrum || settingsApi.showCepstrum) {
            Logger.debug("Extracting user cepstrum (order: " + window.settingsApi.cepstrNumOrder + ")");
            userCepstrData = wavFileApi.getCepstr(
                userWavFileHandle,
                window.settingsApi.specFftLength,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.cepstrNumOrder,
                window.settingsApi.algorithm,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                window.settingsApi.specF0Refinement
            );
            Logger.debug("User cepstrum frames: " + userCepstrData.length);
            userCepstrogramGraph.spectrumData = userCepstrData;
        }

        // ── Pitch derivative ── only when getDP will consume it ─────────────────
        let userPitchDerivData = [];
        if (settingsApi.dpUsePitchDerivative || settingsApi.showPitchDerivative) {
            Logger.debug("Extracting user pitch derivative");
            userPitchDerivData = wavFileApi.getPitchDerivative(
                userWavFileHandle,
                window.settingsApi.algorithm,
                window.settingsApi.frameShift,
                window.settingsApi.sampleRate,
                window.settingsApi.minF0,
                window.settingsApi.maxF0,
                window.settingsApi.voicingThreshold,
                "LOG_F0"
            );
            Logger.debug("User pitch derivative length: " + userPitchDerivData.length);
        }

        // ── DP alignment ───────────────────────────────────────────────────────
        Logger.debug("Calculating DP");
        let scaledLoadedCuePoints = referenceCuePoints.map(cp => ({
            position: Math.round(cp.position * referencePitchData.length / referenceWaveData.length),
            label:    cp.label,
            length:   Math.round(cp.length   * referencePitchData.length / referenceWaveData.length)
        }));

        let dpResult = wavFileApi.getDP(
            referenceAmplitudeData,
            referenceAmplitudeDerivData,
            referencePitchData,
            referenceLogPitchData,
            referencePitchDerivData,
            referenceSpecData,
            referenceCepstrData,
            userAmplitudeData,
            userAmplitudeDerivData,
            userPitchData,
            userLogPitchData,
            userPitchDerivData,
            userSpecData,
            userCepstrData,
            userPitchData,
            scaledLoadedCuePoints
        );
        if (!dpResult || !dpResult.pitch) {
            Logger.debug("DP result is invalid — skipping DP post-processing.");
            return;
        }
        let scaledPitch = dpResult.pitch;
        Logger.debug("DP pitch length: " + scaledPitch.length);

        // Cache DP scalars for the DTW stats display.
        dpMinFinalCost          = dpResult.minFinalCost;
        dpSignalStreamDistances = dpResult.signalStreamDistances;
        dpTemplateData          = dpResult.templateData;
        dpSignalData            = dpResult.signalData;

        // DTW graph updates — skip when the DTW section is hidden.
        if (settingsApi.showDtwAlignment) {
            dtwSignalStreamGraph.waveData = [dpResult.signalStreamDistances];
            templateGraph.waveData        = dpResult.templateData;
            signalGraph.waveData          = dpResult.signalData;
        }

        // ── User UMP — display-only, skip when hidden ──────────────────────────
        if (settingsApi.showUMP && userPitchData.length > 0) {
            Logger.debug("Calculating user UMP");
            let umpResult = wavFileApi.getUMP(
                scaledPitch,
                referenceCuePoints,
                50, 100, 50,
                referenceWaveData.length,
                pitchInterpolationName,
                umpSmoothingName,
                window.settingsApi.umpSmoothingWindowSize,
                window.settingsApi.umpGaussianSmoothingSigma,
                window.settingsApi.umpSplineSmoothingPenalty
            );
            Logger.debug("User UMP cue points: " + umpResult.cuePoints.length);
            userUmpWaveFormGraph.waveData  = umpResult.ump;
            userUmpWaveFormGraph.cuePoints = umpResult.cuePoints;
        }

        // ── Waveform cue point overlays ────────────────────────────────────────
            let scaledCuePoints = dpResult.cuePoints.map(cp => ({
            position: Math.round(cp.position * userWaveData.length   / userLogPitchData.length),
                label:    cp.label,
            length:   Math.round(cp.length   * userWaveData.length   / userLogPitchData.length)
            }));
            userWaveFormGraph.cuePoints = scaledCuePoints;

        if (settingsApi.showProcessedPitch || settingsApi.showF0) {
                let processedScaledCuePoints = dpResult.cuePoints.map(cp => ({
                position: Math.round(cp.position * userPitchData.length / userLogPitchData.length),
                    label:    cp.label,
                length:   Math.round(cp.length   * userPitchData.length / userLogPitchData.length)
                }));
                if (settingsApi.showF0)
                    userPitchWaveFormGraph.cuePoints = processedScaledCuePoints;
                if (settingsApi.showProcessedPitch)
                    userPitchProcessedWaveFormGraph.cuePoints = processedScaledCuePoints;
        }
    }

    title: referenceFilePath.substring(referenceFilePath.lastIndexOf('/') + 1)

    Component.onCompleted: {
        Logger.info("TemplatePage initialization started");

        if (referenceFilePath) {
            Logger.debug("Opening reference WAV file: " + referenceFilePath);
            referenceWavFileHandle = wavFileApi.openWavFile(referenceFilePath);

            Logger.debug("Extracting cue points...");
            referenceCuePoints = wavFileApi.getCuePoints(referenceWavFileHandle);
            Logger.debug("Found " + referenceCuePoints.length + " cue points");

            Logger.debug("Extracting wave data...");
            referenceWaveData = wavFileApi.getWaveData(referenceWavFileHandle);
            Logger.debug("Wave data length: " + referenceWaveData.length);

            refWaveFormGraph.waveData = referenceWaveData;
            refWaveFormGraph.cuePoints = referenceCuePoints;
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
                        text: qsTr("Reference waveform") + " - " + root.referenceFilePath.substring(root.referenceFilePath.lastIndexOf('/') + 1)
                    }

                    WaveFormGraph {
                        id: refWaveFormGraph

                        height: 300
                        width: parent.width - 80
                    }

                    PlayButton {
                        id: refPlayButton

                        file: referenceFilePath
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

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showUMP
                        width: parent.width

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

                    Column {
                        spacing: 10
                        visible: window.settingsApi.showUMP
                        width: parent.width

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

                    Column {
                        spacing: 10
                        width: parent.width
                        visible: settingsApi ? window.settingsApi.showDtwAlignment : true

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Template Data")
                        }

                        WaveFormGraph {
                            id: templateGraph

                            height: 200
                            width: parent.width - 80
                        }
                    }

                    Column {
                        spacing: 10
                        width: parent.width
                        visible: settingsApi ? window.settingsApi.showDtwAlignment : true

                        Text {
                            color: Theme.onSurface(root.Material.theme)
                            font.bold: true
                            font.pixelSize: 16
                            text: qsTr("Signal Data")
                        }

                        WaveFormGraph {
                            id: signalGraph

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
            Layout.preferredWidth: 450
            visible: root.showSettings

            background: Rectangle {
                color: Theme.surface(root.Material.theme)
            }
        }
    }
}
