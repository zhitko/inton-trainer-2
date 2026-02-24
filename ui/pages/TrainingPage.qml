import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.platform 1.1

import by.intontrainer.wavfile 1.0
import by.intontrainer.file 1.0
import by.intontrainer.analysis 1.0

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
    property var referenceWaveData: null
    property var referencePitchData: null
    property var referenceLogPitchData: null
    property var referenceAmplitudeData: null
    property var referenceAmplitudeDerivData: null

    property var userUMP: null
    property double referenceRange: 0
    property double userRange: 0
    property double rangeSimilarity: 0
    property double shapeSimilarity: 0

    WavFileApi {
        id: wavFileApi
    }

    AnalysisApi {
        id: analysisApi
    }

    FileApi {
        id: fileApi
    }

    Component.onCompleted: {
        updateReferenceUMP();
    }

    function updateReferenceUMP() {
        Logger.info("TrainingPage loaded for file: " + referenceFilePath);

        let referenceWavFileHandle = wavFileApi.openWavFile(referenceFilePath);
        referenceCuePoints = wavFileApi.getCuePoints(referenceWavFileHandle);
        referenceWaveData = wavFileApi.getWaveData(referenceWavFileHandle);

        referencePitchData = wavFileApi.getPitch(referenceWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);
        referenceLogPitchData = wavFileApi.getPitch(referenceWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);

        referenceAmplitudeData = wavFileApi.getAmplitude(referenceWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);
        referenceAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(referenceWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);

        referenceUMP = wavFileApi.getUMP(referencePitchData, referenceCuePoints, 50, 100, 50, referenceWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType]);

        umpGraph.waveData = referenceUMP.ump;
        umpGraph.cuePoints = referenceUMP.cuePoints;

        // Extract cepstrum data for reference
        Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
        referenceCepstrData = wavFileApi.getCepstr(referenceWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.cepstrNumOrder, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Cepstrum data frames: " + referenceCepstrData.length);
    }

    function updateUserUMP(fileFullPath) {
        Logger.info("Updating user UMP for file: " + fileFullPath);

        root.userFilePath = fileFullPath;
        let userWavFileHandle = wavFileApi.openWavFile(root.userFilePath);
        let userCuePoints = wavFileApi.getCuePoints(userWavFileHandle);
        let userWaveData = wavFileApi.getWaveData(userWavFileHandle);

        let pitchData = wavFileApi.getPitch(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "PITCH", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);
        let logPitchData = wavFileApi.getPitch(userWavFileHandle, window.settingsApi.algorithm, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, "LOG_F0", window.settingsApi.pitchNormalization, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType], ["None", "MovingAverage", "Median", "Gaussian", "Spline"][window.settingsApi.pitchSmoothing], window.settingsApi.pitchSmoothingWindowSize, window.settingsApi.pitchGaussianSmoothingSigma, window.settingsApi.pitchSplineSmoothingPenalty);

        let userAmplitudeData = wavFileApi.getAmplitude(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);
        let userAmplitudeDerivData = wavFileApi.getAmplitudeDerivative(userWavFileHandle, window.settingsApi.amplitudeWindow, window.settingsApi.amplitudeShift);

        // Extract cepstrum data for user
        Logger.debug("Extracting cepstrum with order: " + window.settingsApi.cepstrNumOrder);
        let userCepstrData = wavFileApi.getCepstr(userWavFileHandle, window.settingsApi.specFftLength, window.settingsApi.frameShift, window.settingsApi.sampleRate, window.settingsApi.cepstrNumOrder, window.settingsApi.algorithm, window.settingsApi.minF0, window.settingsApi.maxF0, window.settingsApi.voicingThreshold, window.settingsApi.specF0Refinement);
        Logger.debug("Cepstrum data frames: " + userCepstrData.length);

        // Generate UMP from DP result
        Logger.debug("Calculating DP...");
        let scaledPitch = wavFileApi.getDP(referenceAmplitudeData, referenceAmplitudeDerivData, referenceLogPitchData, referenceCepstrData, userAmplitudeData, userAmplitudeDerivData, logPitchData, userCepstrData, pitchData, referencePitchData.length);
        Logger.debug("DP result length: " + scaledPitch.length);

        Logger.debug("Calculating UMP...");
        userUMP = wavFileApi.getUMP(scaledPitch, referenceCuePoints, 50, 100, 50, referenceWaveData.length, ["None", "Linear", "Cubic", "Akima", "Monotone"][window.settingsApi.pitchInterpolationType]);
        Logger.debug("UMP calculated with " + userUMP.cuePoints.length + " cue points");

        umpGraph.waveData = [referenceUMP.ump, userUMP.ump];
        umpGraph.cuePoints = referenceUMP.cuePoints;

        // Compare UMPs using AnalysisApi
        var cmp = analysisApi.compareUMP(referenceUMP.ump, userUMP.ump, window.settingsApi.minF0, window.settingsApi.maxF0);
        root.referenceRange = cmp.referenceRange || 0;
        root.userRange = cmp.userRange || 0;
        root.rangeSimilarity = cmp.rangeSimilarity || 0;
        root.shapeSimilarity = cmp.shapeSimilarity || 0;
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
                            text: Math.round(root.rangeSimilarity) + "%"
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
                            text: Math.round(root.shapeSimilarity) + "%"
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
                            width: parent.width * (root.referenceRange / 100.0)
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
                            width: parent.width * (root.userRange / 100.0)
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
                independentScale: true
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
                    console.log("Opening test file dialog: " + fileApi.getApplicationDirPath() + "/data/test");
                    // Ensure the folder exists before opening the dialog
                    if (!fileApi.directoryExists(fileApi.getApplicationDirPath() + "/data/test")) {
                        console.warn("Directory does not exist: " + fileApi.getApplicationDirPath() + "/data/test");
                    } else {
                        // Ensure folder is set immediately before opening (avoid stale bindings)
                        // Use file:// URL to ensure native dialogs interpret it as an absolute path
                        testFileDialog.folder = "file://" + fileApi.getApplicationDirPath() + "/data/test";
                        testFileDialog.open();
                    }
                }
            }

            FileDialog {
                id: testFileDialog
                title: qsTr("Open test file")
                nameFilters: ["WAV files (*.wav)"]
                folder: (fileApi.getApplicationDirPath() + "/data/test") // Set the initial folder to data/test
                onAccepted: {
                    console.log("testFileDialog accepted. folder: " + testFileDialog.folder + ", file: " + testFileDialog.file + ", fileUrl: " + testFileDialog.fileUrl);
                    var selectedPath = null;
                    if (testFileDialog.file !== undefined && testFileDialog.file !== "")
                        selectedPath = testFileDialog.file;
                    else if (testFileDialog.fileUrl)
                        selectedPath = testFileDialog.fileUrl;
                    else if (testFileDialog.fileUrls && testFileDialog.fileUrls.length > 0)
                        selectedPath = testFileDialog.fileUrls[0];

                    // Convert QUrl to string/local path if needed
                    if (selectedPath && typeof selectedPath === "object") {
                        if (selectedPath.toLocalFile)
                            selectedPath = selectedPath.toLocalFile();
                        else if (selectedPath.toString)
                            selectedPath = selectedPath.toString();
                    }

                    if (selectedPath && typeof selectedPath === "string") {
                        var selStr = selectedPath;
                        // Handle file:// URI strings (may contain percent-encoding)
                        if (selStr.indexOf("file://") === 0) {
                            // Strip leading file:// or file:/// and decode percent-encodings
                            selStr = selStr.replace(/^file:\/+/g, "");
                            // For linux add leading slash (windows path started with drive letter 'Z:/')
                            console.log("selStr.indexOf(':/') = " + selStr.indexOf(":/"));
                            if (selStr.indexOf(":/") === -1)
                                selStr = "/" + selStr;
                            try {
                                selStr = decodeURIComponent(selStr);
                            } catch (e) {
                                // ignore decode errors and keep as-is
                            }
                        }

                        updateUserUMP(selStr);
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

            Item {
                Layout.preferredHeight: 24
            }
        }
    }
}
