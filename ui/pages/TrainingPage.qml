import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Effects

import by.intontrainer.wavfile 1.0
import by.intontrainer.file 1.0
import by.intontrainer.analysis 1.0
import by.intontrainer.statistics 1.0
import by.intontrainer.audio 1.0

import "../components"
import "../utils"

Page {
    id: root

    // ── Page state ──────────────────────────────────────────────────────────
    property string referenceFilePath: ""
    property string userFilePath:      ""
    property string titleText: referenceFilePath.substring(referenceFilePath.lastIndexOf('/') + 1).replace(".wav", "")

    title: titleText

    // Shorthand computed accessors for repeated index→string lookups
    readonly property string pitchInterpolationName: settingsApi ? ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType] : "None"
    readonly property string pitchSmoothingName:     settingsApi ? ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing]    : "None"
    readonly property string amplitudeSmoothingName:  settingsApi ? ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing]           : "None"
    readonly property string umpSmoothingName:        settingsApi ? ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.umpSmoothing]       : "None"

    // ── Reference audio data ───────────────────────────────────────────────
    property var referenceUMP:              null
    property var referenceCuePoints:        null
    property var referenceWaveData:         null
    property var referencePitchData:        null
    property var referenceLogPitchData:     null
    property var referenceAmplitudeData:    null
    property var referenceAmplitudeDerivData: null
    property var referencePitchDerivData:   null
    property var referenceSpecData:         null
    property var referenceCepstrData:       null

    // ── User results ─────────────────────────────────────────────────────
    property var    userUMP:                  null
    property double shapeSimilarity:          0
    property var    previousShapeSimilarities: []

    WavFileApi {
        id: wavFileApi
    }

    AnalysisApi {
        id: analysisApi
    }

    FileApi {
        id: fileApi
    }

    StatisticsApi {
        id: statisticsApi
    }

    AudioApi {
        id: trainingAudioApi
    }

    property bool _isExiting: false

    onVisibleChanged: {
        if (visible) {
            _isExiting = false;
            // Guard against uninitialized window.settingsApi during destruction/initialization
            if (window.settingsApi && window.settingsApi.autoStopRecording && !trainingAudioApi.isRecording) {
                trainingAudioApi.startRecording();
            }
        } else {
            _isExiting = true;
            if (trainingAudioApi.isRecording) {
                trainingAudioApi.stopRecording();
            }
        }
    }

    Component.onDestruction: {
        _isExiting = true;
        if (trainingAudioApi.isRecording) {
            trainingAudioApi.stopRecording();
        }
    }

    Connections {
        target: trainingAudioApi
        onIsRecordingChanged: {
            if (!trainingAudioApi.isRecording && !root._isExiting && window.settingsApi && window.settingsApi.autoStopRecording) {
                let tempFilePath = trainingAudioApi.saveWavFile();
                if (tempFilePath !== "") {
                    let userWavHandle = wavFileApi.openWavFile(tempFilePath);
                    let userWaveData = wavFileApi.getWaveData(userWavHandle);
                    
                    if (root.referenceWaveData && userWaveData && userWaveData.length >= root.referenceWaveData.length * 0.8) {
                        Logger.info("Recording successful, length is sufficient.");
                        updateUserUMP(tempFilePath, true);
                    } else {
                        Logger.info("Recording too short, discarding. Required: " + (root.referenceWaveData ? root.referenceWaveData.length * 0.8 : 0) + ", got: " + (userWaveData ? userWaveData.length : 0));
                        // Let the UI know or just wait in silence
                    }
                }
                // Restart recording after a small delay if playback isn't active
                if (!isAnyPlaybackActive && window.settingsApi && window.settingsApi.autoStopRecording) {
                    restartRecordingTimer.start();
                }
            }
        }
    }

    Timer {
        id: restartRecordingTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.visible && !root._isExiting) {
                trainingAudioApi.startRecording();
            }
        }
    }

    property bool isAnyPlaybackActive: playReferenceBtn.isPlaying || playUserBtn.isPlaying

    onIsAnyPlaybackActiveChanged: {
        if (isAnyPlaybackActive && trainingAudioApi.isRecording) {
            _isExiting = true; // Set to true so we don't save the aborted recording
            trainingAudioApi.stopRecording();
            _isExiting = false; // reset immediately
        } else if (!isAnyPlaybackActive && !trainingAudioApi.isRecording) {
            // Un-pause recording when playback finishes
            restartRecordingTimer.start();
        }
    }

    Component.onCompleted: {
        updateReferenceUMP();
        loadPreviousResults();
        
        if (visible && window.settingsApi && window.settingsApi.autoStopRecording && !trainingAudioApi.isRecording) {
            _isExiting = false;
            trainingAudioApi.startRecording();
        }
    }

    Connections {
        target: window.settingsApi

        function onSettingsChanged() {
            Logger.debug("TrainingPage onSettingsChanged: refreshing reference UMP");
            root.updateReferenceUMP();
        }
    }

    function loadPreviousResults() {
        let results = statisticsApi.getResultsForFile(root.referenceFilePath);
        if (results && results.length > 0) {
            // Exclude the latest (current) result, take up to 5 previous ones
            // Reverse so index 0 = most recent previous (shown largest on the left)
            let histResults = results.slice(0, -1).slice(-5).reverse();
            root.previousShapeSimilarities = histResults.map(v => Math.round(v));
            // Set current similarity to the latest result if no new recording yet
            if (root.shapeSimilarity === 0) {
                root.shapeSimilarity = results[results.length - 1];
            }
        }
    }

    function updateReferenceUMP() {
        Logger.info("Loading reference file: " + referenceFilePath);

        let referenceWavFileHandle = wavFileApi.openWavFile(referenceFilePath);
        referenceCuePoints = wavFileApi.getCuePoints(referenceWavFileHandle);
        referenceWaveData  = wavFileApi.getWaveData(referenceWavFileHandle);

        // ── Pitch ───────────────────────────────────────────────────────────
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
            false,
            window.settingsApi.useOnlyN
        );
        Logger.debug("Reference pitch frames: " + referencePitchData.length);

        // Log pitch — only when dpUsePitchLog or dpUsePitchLogAsMask is active
        if (settingsApi.dpUsePitchLog || settingsApi.dpUsePitchLogAsMask) {
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
            Logger.debug("Reference log pitch frames: " + referenceLogPitchData.length);
        } else {
            referenceLogPitchData = [];
        }

        // Pitch derivative — only when dpUsePitchDerivative is active
        if (settingsApi.dpUsePitchDerivative) {
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
            Logger.debug("Reference pitch derivative frames: " + referencePitchDerivData.length);
        } else {
            referencePitchDerivData = [];
        }

        // ── Amplitude ── only when dpUseAmplitude / dpUseAmplitudeDerivative is active
        if (settingsApi.dpUseAmplitude) {
            referenceAmplitudeData = wavFileApi.getAmplitude(
                referenceWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
        } else {
            referenceAmplitudeData = [];
        }

        if (settingsApi.dpUseAmplitudeDerivative) {
            referenceAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(
                referenceWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
        } else {
            referenceAmplitudeDerivData = [];
        }

        // ── UMP ───────────────────────────────────────────────────────────
        root.referenceUMP = wavFileApi.getUMP(
            referencePitchData,
            referenceCuePoints,
            50, 100, 50,
            referenceWaveData.length,
            pitchInterpolationName,
            umpSmoothingName,
            window.settingsApi.umpSmoothingWindowSize,
            window.settingsApi.umpGaussianSmoothingSigma,
            window.settingsApi.umpSplineSmoothingPenalty,
            false
        );
        umpGraph.waveData  = root.referenceUMP.ump;
        umpGraph.cuePoints = root.referenceUMP.cuePoints;

        // ── Spectrum / Cepstrum ── only when dpUseSpectrum / dpUseCepstrum is active
        if (settingsApi.dpUseCepstrum) {
            Logger.debug("Extracting cepstrum (order: " + window.settingsApi.cepstrNumOrder + ")");
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
        } else {
            referenceCepstrData = [];
        }

        if (settingsApi.dpUseSpectrum) {
            Logger.debug("Extracting spectrum (FFT: " + window.settingsApi.specFftLength + ")");
            referenceSpecData = wavFileApi.getSpec(
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
            Logger.debug("Reference spectrum frames: " + referenceSpecData.length);
        } else {
            referenceSpecData = [];
        }
    }

    function updateUserUMP(fileFullPath, isMicrophoneRecording) {
        Logger.info("Updating user UMP for file: " + fileFullPath + " isMicrophone: " + isMicrophoneRecording);

        root.userFilePath = fileFullPath;
        let userWavFileHandle = wavFileApi.openWavFile(root.userFilePath);
        let userCuePoints = wavFileApi.getCuePoints(userWavFileHandle);
        let userWaveData = wavFileApi.getWaveData(userWavFileHandle);

        // ── Pitch ───────────────────────────────────────────────────────────
        let userPitchData = wavFileApi.getPitch(
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
        Logger.debug("Pitch data frames: " + userPitchData.length);

        // Log pitch — only when dpUsePitchLog or dpUsePitchLogAsMask is active
        let userLogPitchData = [];
        if (settingsApi.dpUsePitchLog || settingsApi.dpUsePitchLogAsMask) {
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
            Logger.debug("Log pitch data frames: " + userLogPitchData.length);
        }

        // ── Amplitude ── only when dpUseAmplitude / dpUseAmplitudeDerivative is active
        let userAmplitudeData = [];
        if (settingsApi.dpUseAmplitude) {
            Logger.debug("Extracting user amplitude");
            userAmplitudeData = wavFileApi.getAmplitude(
                userWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
        }

        let userAmplitudeDerivData = [];
        if (settingsApi.dpUseAmplitudeDerivative) {
            Logger.debug("Extracting user amplitude derivative");
            userAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(
                userWavFileHandle,
                window.settingsApi.amplitudeWindow,
                window.settingsApi.amplitudeShift,
                amplitudeSmoothingName,
                window.settingsApi.amplitudeSmoothingWindowSize,
                window.settingsApi.amplitudeGaussianSmoothingSigma
            );
        }

        // ── Cepstrum ── only when dpUseCepstrum is active
        let userCepstrData = [];
        if (settingsApi.dpUseCepstrum) {
            Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
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
            Logger.debug("Cepstrum data frames: " + userCepstrData.length);
        }

        // ── Spectrum ── only when dpUseSpectrum is active
        let userSpecData = [];
        if (settingsApi.dpUseSpectrum) {
            Logger.debug("Extracting spectrum with FFT length: " + window.settingsApi.specFftLength);
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
            Logger.debug("User spectrum data frames: " + userSpecData.length);
        }

        // ── Pitch derivative ── only when dpUsePitchDerivative is active
        let userPitchDerivData = [];
        if (settingsApi.dpUsePitchDerivative) {
            Logger.debug("Extracting pitch derivative data for user");
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
            Logger.debug("User pitch derivative data frames: " + userPitchDerivData.length);
        }

        // Generate UMP from DP result
        // Scale loadedCuePoints to match user pitch data length
        let scaledLoadedCuePoints = referenceCuePoints.map(cp => {
            return {
                position: Math.round(cp.position * referencePitchData.length / referenceWaveData.length),
                label: cp.label,
                length: Math.round(cp.length * referencePitchData.length / referenceWaveData.length)
            };
        });
        Logger.debug("Calculating DP...");
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
        let scaledPitch = dpResult.pitch;
        Logger.debug("DP result pitch length: " + scaledPitch.length);

        Logger.debug("Calculating UMP...");
        root.userUMP = wavFileApi.getUMP(
            scaledPitch, 
            referenceCuePoints, 
            50, 100, 50, 
            referenceWaveData.length, 
            pitchInterpolationName, 
            umpSmoothingName, 
            window.settingsApi.umpSmoothingWindowSize, 
            window.settingsApi.umpGaussianSmoothingSigma, 
            window.settingsApi.umpSplineSmoothingPenalty, 
            false
        );
        Logger.debug("UMP calculated with " + root.userUMP.cuePoints.length + " cue points");

        umpGraph.waveData = [root.referenceUMP.ump, root.userUMP.ump];
        umpGraph.cuePoints = root.userUMP.cuePoints;

        // Compare UMPs using AnalysisApi to get similarity
        var cmp = analysisApi.compareUMP(root.referenceUMP.ump, root.userUMP.ump, window.settingsApi.minF0, window.settingsApi.maxF0);
        var newShapeSimilarity = cmp.shapeSimilarity || 0;

        if (root.shapeSimilarity > 0) {
            root.previousShapeSimilarities = [Math.round(root.shapeSimilarity)].concat(root.previousShapeSimilarities).slice(0, 5);
        }
        root.shapeSimilarity = newShapeSimilarity;

        // Register the result in statistics FIRST
        statisticsApi.registerResult(root.referenceFilePath, root.shapeSimilarity);

        // Register history entry for the user record only if it was a microphone recording
        if (isMicrophoneRecording) {
            statisticsApi.registerHistoryEntry(root.userFilePath, root.referenceFilePath, root.shapeSimilarity);
        }

        // Then reload history so previous results reflect the newly saved state
        loadPreviousResults();
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
            spacing: 20

            // Shape Similarity Card
            Rectangle {
                id: shapeSimilarityCard
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                color: Theme.secondaryContainer(root.Material.theme)
                radius: 16

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.15)
                    blur: 0.5
                    shadowVerticalOffset: 6
                }

                // Card title — top-left corner
                Text {
                    id: cardTitle
                    anchors {
                        verticalCenter: currentResultColumn.verticalCenter
                        left: parent.left
                        leftMargin: 36
                    }
                    text: qsTr("Shape Similarity")
                    font.pixelSize: 24
                    font.weight: 600
                    color: Theme.onSecondaryContainer(root.Material.theme)
                    opacity: 0.55
                }

                // Current result — centered
                Column {
                    id: currentResultColumn
                    anchors {
                        centerIn: parent
                        verticalCenterOffset: 0
                    }
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(root.shapeSimilarity) + "%"
                        font.pixelSize: 46
                        font.weight: 700
                        color: Theme.primary(root.Material.theme)

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: currentResultColumn
                                    property: "scale"
                                    from: 1.0
                                    to: 1.12
                                    duration: 120
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    target: currentResultColumn
                                    property: "scale"
                                    from: 1.12
                                    to: 1.0
                                    duration: 180
                                    easing.type: Easing.OutBack
                                }
                            }
                        }
                    }

                    // Trend indicator: show delta vs most recent previous result
                    Text {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenterOffset: -10
                        }
                        visible: root.previousShapeSimilarities.length > 0
                        property int delta: root.previousShapeSimilarities.length > 0 ? Math.round(root.shapeSimilarity) - root.previousShapeSimilarities[0] : 0
                        text: delta > 0 ? ("▲ +" + delta + "%") : (delta < 0 ? ("▼ " + delta + "%") : "● 0%")
                        font.pixelSize: 12
                        font.weight: 600
                        color: delta > 0 ? "#4caf50" : (delta < 0 ? "#ef5350" : Theme.onSecondaryContainer(root.Material.theme))
                        opacity: 0.85
                    }
                }

                // Separator arrow: current → history
                Text {
                    id: separatorArrow
                    anchors {
                        left: currentResultColumn.right
                        leftMargin: 6
                        verticalCenter: currentResultColumn.verticalCenter
                    }
                    visible: root.previousShapeSimilarities.length > 0
                    text: "›"
                    font.pixelSize: 20
                    color: Theme.primary(root.Material.theme)
                    opacity: 0.7
                }

                // Previous results — right side
                // index 0 = most recent (closest to center, largest/boldest)
                // index N = oldest (far right, smallest/most faded)
                Row {
                    id: previousResultsRow
                    anchors {
                        left: separatorArrow.right
                        leftMargin: 16
                        verticalCenter: parent.verticalCenter
                        verticalCenterOffset: 0
                    }
                    spacing: 0
                    visible: root.previousShapeSimilarities.length > 0

                    Repeater {
                        model: root.previousShapeSimilarities

                        delegate: Item {
                            property int baseSize: 22
                            property int minSize: 10
                            property real scaledSize: Math.max(minSize, baseSize - index * 3)
                            property real scaledOpacity: Math.max(0.15, 0.55 - index * 0.10)

                            width: valueText.implicitWidth + (arrowText.visible ? arrowText.implicitWidth : 0) + 2
                            height: 60

                            Text {
                                id: valueText
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData + "%"
                                font.pixelSize: scaledSize
                                font.weight: index === 0 ? 600 : 500
                                color: Theme.onSecondaryContainer(root.Material.theme)
                                opacity: scaledOpacity
                            }

                            // Arrow separator after each value (except the last)
                            Text {
                                id: arrowText
                                anchors {
                                    left: valueText.right
                                    verticalCenter: parent.verticalCenter
                                }
                                visible: index < root.previousShapeSimilarities.length
                                text: " ›"
                                font.pixelSize: scaledSize * 0.7
                                color: Theme.onSecondaryContainer(root.Material.theme)
                                opacity: scaledOpacity * 0.6
                            }
                        }
                    }
                }
            }

            // Main Graph
            WaveFormGraph {
                id: umpGraph
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 400
                independentScale: true
                datasetColors: ["#d62728", "#83270b"]
                lineWidth: 5
                showCueLabels: false
                cueNLabels: root.titleText.replace(/\([^)]*\)/g, "").replace(/\d+/, "").replace("-", "").split(",").map(s => s.trim())
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 32

                PlayRoundButton {
                    id: playReferenceBtn
                    filePath: root.referenceFilePath
                    text: qsTr("Play\nReference")
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8
                    Layout.preferredWidth: 220
                    visible: window.settingsApi ? window.settingsApi.autoStopRecording : false

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            // Change color based on playback or recording
                            color: isAnyPlaybackActive ? Theme.primary(root.Material.theme) : Theme.error(root.Material.theme)
                            visible: trainingAudioApi.isRecording || isAnyPlaybackActive

                            SequentialAnimation on opacity {
                                running: trainingAudioApi.isRecording || isAnyPlaybackActive
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.2; duration: 800; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.2; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                            }
                        }

                        Text {
                            text: isAnyPlaybackActive ? qsTr("Playing...") : (trainingAudioApi.isRecording ? (trainingAudioApi.isVoiceDetected ? qsTr("Recording...") : qsTr("Listening...")) : qsTr("Processing..."))
                            font.pixelSize: 18
                            font.weight: 600
                            color: isAnyPlaybackActive ? Theme.primary(root.Material.theme) : (trainingAudioApi.isRecording ? Theme.error(root.Material.theme) : Theme.onSurface(root.Material.theme))
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: isAnyPlaybackActive ? qsTr("Listen carefully") : qsTr("Repeat the phrase into the mic")
                        font.pixelSize: 14
                        color: Theme.onSurface(root.Material.theme)
                        opacity: 0.6
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                RecordRoundButton {
                    id: manualRecordBtn
                    Layout.alignment: Qt.AlignVCenter
                    visible: window.settingsApi ? !window.settingsApi.autoStopRecording : false
                    onRecordingFinished: function(filePath) {
                        if (filePath !== "") {
                            root.updateUserUMP(filePath, true);
                        }
                    }
                }

                PlayRoundButton {
                    id: playUserBtn
                    filePath: root.userFilePath
                    text: qsTr("Play\nMe")
                    opacity: root.userFilePath !== "" ? 1.0 : 0.0
                    enabled: root.userFilePath !== ""
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 250 }
                    }
                }
            }

            // Open Test File Button
            Button {
                id: openTestFileButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 48
                flat: false

                contentItem: Text {
                    text: qsTr("Open Test File")
                    font.pixelSize: 16
                    font.weight: 600
                    color: openTestFileButton.down ? Qt.darker(Theme.onPrimary(root.Material.theme), 1.1) : Theme.onPrimary(root.Material.theme)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 24
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: openTestFileButton.hovered ? Qt.lighter(Theme.primary(root.Material.theme), 1.1) : Theme.primary(root.Material.theme)
                        }
                        GradientStop {
                            position: 1.0
                            color: openTestFileButton.hovered ? Theme.primary(root.Material.theme) : Qt.darker(Theme.primary(root.Material.theme), 1.2)
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
                        blur: openTestFileButton.hovered ? 0.3 : 0.2
                        shadowVerticalOffset: openTestFileButton.hovered ? 6 : 4
                    }

                    scale: openTestFileButton.pressed ? 0.95 : (openTestFileButton.hovered ? 1.02 : 1.0)
                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutBack
                        }
                    }
                }

                onClicked: {
                    var testFolderPath = fileApi.getApplicationDirPath() + "/data/test";
                    console.log("Opening test file dialog: " + testFolderPath);
                    if (!fileApi.directoryExists(testFolderPath)) {
                        console.warn("Directory does not exist: " + testFolderPath);
                    } else {
                        // Use FileApi helper to get properly formatted URL (crucial for Windows to avoid UNC timeout)
                        testFileDialog.currentFolder = fileApi.getUrlFromPath(testFolderPath);
                        testFileDialog.open();
                    }
                }
            }

            FileDialog {
                id: testFileDialog
                title: qsTr("Open test file")
                nameFilters: ["WAV files (*.wav)"]
                onAccepted: {
                    console.log("testFileDialog accepted: " + testFileDialog.selectedFile);
                    var selectedPath = fileApi.getPathFromUrl(testFileDialog.selectedFile);
                    if (selectedPath) {
                        updateUserUMP(selectedPath, false);
                    }
                }
            }

            // Advanced Button
            Button {
                id: advancedButton
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: 128
                Layout.preferredHeight: 36
                Layout.rightMargin: 12
                Layout.bottomMargin: 8
                flat: false

                contentItem: Text {
                    text: qsTr("Advanced")
                    font.pixelSize: 13
                    font.weight: 500
                    color: advancedButton.down ? Qt.darker(Theme.onSecondaryContainer(root.Material.theme), 1.1) : Theme.onSecondaryContainer(root.Material.theme)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                background: Rectangle {
                    radius: 18
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: advancedButton.hovered ? Qt.lighter(Theme.primaryContainer(root.Material.theme), 1.08) : Theme.primaryContainer(root.Material.theme)
                        }
                        GradientStop {
                            position: 1.0
                            color: advancedButton.hovered ? Theme.primaryContainer(root.Material.theme) : Qt.darker(Theme.primaryContainer(root.Material.theme), 1.08)
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
                        referenceFilePath: root.referenceFilePath,
                        userFilePath: root.userFilePath,
                        userVadA: trainingAudioApi.getVadA(),
                        userVadU: trainingAudioApi.getVadU(),
                        userVadV: trainingAudioApi.getVadV()
                    });
                }
            }
        }
    }
}
