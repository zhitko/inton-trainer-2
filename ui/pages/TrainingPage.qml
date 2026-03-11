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

import "../components"
import "../utils"

Page {
    id: root
    property string referenceFilePath: ""
    property string userFilePath: ""
    property string titleText: referenceFilePath.substring(referenceFilePath.lastIndexOf('/') + 1).replace(".wav", "")

    title: titleText

    property var referenceUMP: null
    property var referenceCuePoints: null
    property var referenceCepstrData: null
    property var referenceSpecData: null
    property var referenceWaveData: null
    property var referencePitchData: null
    property var referenceLogPitchData: null
    property var referenceAmplitudeData: null
    property var referenceAmplitudeDerivData: null
    property var referencePitchDerivData: null

    property var userUMP: null
    property double shapeSimilarity: 0
    property var previousShapeSimilarities: []

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

    Component.onCompleted: {
        updateReferenceUMP();
        loadPreviousResults();
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
        Logger.info("TrainingPage loaded for file: " + referenceFilePath);

        let referenceWavFileHandle = wavFileApi.openWavFile(referenceFilePath);
        referenceCuePoints = wavFileApi.getCuePoints(referenceWavFileHandle);
        referenceWaveData = wavFileApi.getWaveData(referenceWavFileHandle);

        referencePitchData = wavFileApi.getPitch(referenceWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty, false);
        Logger.debug("Reference pitch data frames: " + referencePitchData.length);
        referenceLogPitchData = wavFileApi.getPitch(referenceWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0", "None", "None", 0, 0, 0);
        Logger.debug("Reference log pitch data frames: " + referenceLogPitchData.length);

        referenceAmplitudeData = wavFileApi.getAmplitude(referenceWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);
        referenceAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(referenceWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);

        root.referenceUMP = wavFileApi.getUMP(referencePitchData, referenceCuePoints, 50, 100, 50, referenceWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], false);

        umpGraph.waveData = root.referenceUMP.ump;
        umpGraph.cuePoints = root.referenceUMP.cuePoints;

        // Extract cepstrum data for reference
        Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
        referenceCepstrData = wavFileApi.getCepstr(referenceWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.cepstrNumOrder, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Cepstrum data frames: " + referenceCepstrData.length);

        // Extract spectrum data for reference
        Logger.debug("Extracting spectrum with FFT length: " + window.settingsApi.specFftLength);
        referenceSpecData = wavFileApi.getSpec(referenceWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Reference spectrum data frames: " + referenceSpecData.length);

        // Extract pitch derivative data for reference
        Logger.debug("Extracting pitch derivative data for reference");
        referencePitchDerivData = wavFileApi.getPitchDerivative(referenceWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0");
        Logger.debug("Reference pitch derivative data frames: " + referencePitchDerivData.length);
    }

    function updateUserUMP(fileFullPath) {
        Logger.info("Updating user UMP for file: " + fileFullPath);

        root.userFilePath = fileFullPath;
        let userWavFileHandle = wavFileApi.openWavFile(root.userFilePath);
        let userCuePoints = wavFileApi.getCuePoints(userWavFileHandle);
        let userWaveData = wavFileApi.getWaveData(userWavFileHandle);

        let pitchData = wavFileApi.getPitch(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty, false);
        Logger.debug("Pitch data frames: " + pitchData.length);
        let logPitchData = wavFileApi.getPitch(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0", "None", "None", 0, 0, 0);
        Logger.debug("Log pitch data frames: " + logPitchData.length);

        let userAmplitudeData = wavFileApi.getAmplitude(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);
        let userAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift, ["None", "MovingAverage", "Median", "Gaussian"][window.settingsApi.amplitudeSmoothing], window.settingsApi.amplitudeSmoothingWindowSize, window.settingsApi.amplitudeGaussianSmoothingSigma);

        // Extract cepstrum data for user
        Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
        let userCepstrData = wavFileApi.getCepstr(userWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.cepstrNumOrder, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Cepstrum data frames: " + userCepstrData.length);

        // Extract spectrum data for user
        Logger.debug("Extracting spectrum with FFT length: " + window.settingsApi.specFftLength);
        let userSpecData = wavFileApi.getSpec(userWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("User spectrum data frames: " + userSpecData.length);

        // Extract pitch derivative data for user
        Logger.debug("Extracting pitch derivative data for user");
        let userPitchDerivData = wavFileApi.getPitchDerivative(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0");
        Logger.debug("User pitch derivative data frames: " + userPitchDerivData.length);

        // Generate UMP from DP result
        Logger.debug("Calculating DP...");
        let dpResult = wavFileApi.getDP(referenceAmplitudeData, referenceAmplitudeDerivData, referenceLogPitchData, referenceLogPitchData, referencePitchDerivData, referenceSpecData, referenceCepstrData, userAmplitudeData, userAmplitudeDerivData, logPitchData, logPitchData, userPitchDerivData, userSpecData, userCepstrData, pitchData, referenceCuePoints);
        let scaledPitch = dpResult.pitch;
        Logger.debug("DP result pitch length: " + scaledPitch.length);

        Logger.debug("Calculating UMP...");
        root.userUMP = wavFileApi.getUMP(scaledPitch, referenceCuePoints, 50, 100, 50, referenceWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], false);
        Logger.debug("UMP calculated with " + root.userUMP.cuePoints.length + " cue points");

        umpGraph.waveData = [root.referenceUMP.ump, root.userUMP.ump];
        umpGraph.cuePoints = root.referenceUMP.cuePoints;

        // Compare UMPs using AnalysisApi to get similarity
        var cmp = analysisApi.compareUMP(root.referenceUMP.ump, root.userUMP.ump, window.settingsApi.minF0, window.settingsApi.maxF0);
        var newShapeSimilarity = cmp.shapeSimilarity || 0;

        if (root.shapeSimilarity > 0) {
            root.previousShapeSimilarities = [Math.round(root.shapeSimilarity)].concat(root.previousShapeSimilarities).slice(0, 5);
        }
        root.shapeSimilarity = newShapeSimilarity;

        // Register the result in statistics FIRST
        statisticsApi.registerResult(root.referenceFilePath, root.shapeSimilarity);

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
                    filePath: root.referenceFilePath
                    text: qsTr("Play\nReference")
                }

                RecordRoundButton {
                    filePath: root.userFilePath
                    onRecordingFinished: updateUserUMP(filePath)
                }

                PlayRoundButton {
                    filePath: root.userFilePath
                    text: qsTr("Play\nMe")
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
                        updateUserUMP(selectedPath);
                    }
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
                        refFilePath: root.referenceFilePath,
                        userFilePath: root.userFilePath
                    });
                }
            }
        }
    }
}
