import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.settings 1.0
import "../utils"

Page {
    id: root
    title: qsTr("Settings")

    readonly property var settingsApi: ApplicationWindow.window ? ApplicationWindow.window.settingsApi : null

    Material.theme: ApplicationWindow.window ? ApplicationWindow.window.theme : Material.Light

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20

            Frame {
                Layout.fillWidth: true
                Layout.margins: 20

                background: Rectangle {
                    color: Theme.surfaceContainerLow(Material.theme)
                    radius: 16
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: qsTr("General")
                        font.bold: true
                        font.pixelSize: 20
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Language")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["en", "ru"]
                            currentIndex: settingsApi ? model.indexOf(settingsApi.language) : 0
                            onActivated: if (settingsApi)
                                settingsApi.language = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Language Title")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.languageTitle : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.languageTitle = text
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Theme")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            textRole: "name"
                            valueRole: "id"
                            model: [
                                {
                                    "name": qsTr("Light"),
                                    "id": "light"
                                },
                                {
                                    "name": qsTr("Dark"),
                                    "id": "dark"
                                },
                                {
                                    "name": qsTr("System"),
                                    "id": "system"
                                }
                            ]
                            currentIndex: {
                                if (!settingsApi)
                                    return 0;
                                for (var i = 0; i < model.length; i++) {
                                    if (model[i].id === settingsApi.theme)
                                        return i;
                                }
                                return 0;
                            }
                            onActivated: if (settingsApi)
                                settingsApi.theme = model[index].id
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Primary Color")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            textRole: "name"
                            valueRole: "id"
                            model: [
                                {
                                    name: qsTr("Blue"),
                                    id: "blue"
                                },
                                {
                                    name: qsTr("Green"),
                                    id: "green"
                                },
                                {
                                    name: qsTr("Purple"),
                                    id: "purple"
                                },
                                {
                                    name: qsTr("Orange"),
                                    id: "orange"
                                },
                                {
                                    name: qsTr("Red"),
                                    id: "red"
                                },
                                {
                                    name: qsTr("Stainless Steel"),
                                    id: "stainless_steel"
                                }
                            ]
                            currentIndex: {
                                if (!settingsApi)
                                    return 0;
                                for (var i = 0; i < model.length; i++) {
                                    if (model[i].id === settingsApi.primaryColor)
                                        return i;
                                }
                                return 0;
                            }
                            onActivated: if (settingsApi)
                                settingsApi.primaryColor = model[index].id
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Show Navigation Menu")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showNavigationMenu : false
                            onToggled: if (settingsApi)
                                settingsApi.showNavigationMenu = checked
                        }
                    }

                    Button {
                        text: qsTr("Delete user data")
                        Layout.fillWidth: true
                        Material.foreground: Theme.onError(Material.theme)

                        background: Rectangle {
                            color: Theme.error(Material.theme)
                            radius: 4
                        }

                        onClicked: {
                            confirmationDialog.open();
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 20

                background: Rectangle {
                    color: Theme.surfaceContainerLow(Material.theme)
                    radius: 16
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: qsTr("Pitch")
                        font.bold: true
                        font.pixelSize: 20
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Show F0")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showF0 : false
                            onToggled: if (settingsApi)
                                settingsApi.showF0 = checked
                        }

                        Label {
                            text: qsTr("Show Processed Pitch (F0)")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showProcessedPitch : false
                            onToggled: if (settingsApi)
                                settingsApi.showProcessedPitch = checked
                        }

                        Label {
                            text: qsTr("Show Log Pitch (LOG_F0)")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showLogPitch : false
                            onToggled: if (settingsApi)
                                settingsApi.showLogPitch = checked
                        }

                        Label {
                            text: qsTr("Algorithm")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["RAPT"]
                            currentIndex: settingsApi ? model.indexOf(settingsApi.algorithm) : 0
                            onActivated: if (settingsApi)
                                settingsApi.algorithm = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Frame Shift (ms)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.frameShift.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.frameShift = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Sample Rate (Hz)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.sampleRate.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.sampleRate = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Min F0 (Hz)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.minF0.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.minF0 = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Max F0 (Hz)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.maxF0.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.maxF0 = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Voicing Threshold")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.voicingThreshold.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.voicingThreshold = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Pitch Normalization")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["min_max", "mean"]
                            currentIndex: settingsApi ? model.indexOf(settingsApi.pitchNormalization) : 0
                            onActivated: if (settingsApi)
                                settingsApi.pitchNormalization = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Pitch Interpolation")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["None", "Linear", "Cubic", "Akima", "Monotone"]
                            currentIndex: settingsApi ? settingsApi.pitchInterpolationType : 0
                            onActivated: if (settingsApi)
                                settingsApi.pitchInterpolationType = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Pitch Smoothing")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["None", "MovingAverage", "Median", "Gaussian", "Spline"]
                            currentIndex: settingsApi ? settingsApi.pitchSmoothing : 0
                            onActivated: if (settingsApi)
                                settingsApi.pitchSmoothing = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Smoothing Window Size")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.pitchSmoothing !== 4 : false // Hide for Spline (4)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.pitchSmoothingWindowSize.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.pitchSmoothingWindowSize = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: settingsApi ? settingsApi.pitchSmoothing !== 4 : false // Hide for Spline (4)
                        }

                        Label {
                            text: qsTr("Gaussian Sigma")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.pitchSmoothing === 3 : false // Show only for Gaussian (3)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.pitchGaussianSmoothingSigma.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.pitchGaussianSmoothingSigma = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: settingsApi ? settingsApi.pitchSmoothing === 3 : false // Show only for Gaussian (3)
                        }

                        Label {
                            text: qsTr("Spline Penalty")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.pitchSmoothing === 4 : false // Show only for Spline (4)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.pitchSplineSmoothingPenalty.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.pitchSplineSmoothingPenalty = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: settingsApi ? settingsApi.pitchSmoothing === 4 : false // Show only for Spline (4)
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 20

                background: Rectangle {
                    color: Theme.surfaceContainerLow(Material.theme)
                    radius: 16
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    // Amplitude settings section
                    Label {
                        text: qsTr("Amplitude")
                        font.bold: true
                        font.pixelSize: 20
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Show Amplitude")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showAmplitude : false
                            onToggled: if (settingsApi)
                                settingsApi.showAmplitude = checked
                        }

                        Label {
                            text: qsTr("Show Amplitude Derivative")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showAmplitudeDerivative : false
                            onToggled: if (settingsApi)
                                settingsApi.showAmplitudeDerivative = checked
                        }

                        Label {
                            text: qsTr("Window")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.amplitudeWindow.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.amplitudeWindow = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Shift")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.amplitudeShift.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.amplitudeShift = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Smoothing")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["None", "MovingAverage", "Median", "Gaussian"]
                            currentIndex: settingsApi ? settingsApi.amplitudeSmoothing : 0
                            onActivated: if (settingsApi)
                                settingsApi.amplitudeSmoothing = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Smoothing Window Size")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.amplitudeSmoothing !== 0 : false // Hide for None
                        }
                        TextField {
                            text: settingsApi ? settingsApi.amplitudeSmoothingWindowSize.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.amplitudeSmoothingWindowSize = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            visible: settingsApi ? settingsApi.amplitudeSmoothing !== 0 : false // Hide for None
                        }

                        Label {
                            text: qsTr("Gaussian Sigma")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.amplitudeSmoothing === 3 : false // Show only for Gaussian (3)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.amplitudeGaussianSmoothingSigma.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.amplitudeGaussianSmoothingSigma = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: settingsApi ? settingsApi.amplitudeSmoothing === 3 : false // Show only for Gaussian (3)
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 20

                background: Rectangle {
                    color: Theme.surfaceContainerLow(Material.theme)
                    radius: 16
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: qsTr("Spectrum")
                        font.bold: true
                        font.pixelSize: 20
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Show Spectrum")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showSpectrum : false
                            onToggled: if (settingsApi)
                                settingsApi.showSpectrum = checked
                        }

                        Label {
                            text: qsTr("Show Cepstrum")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showCepstrum : false
                            onToggled: if (settingsApi)
                                settingsApi.showCepstrum = checked
                        }

                        Label {
                            text: qsTr("FFT Length")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: [1024, 2048, 4096, 8192]
                            currentIndex: settingsApi ? model.indexOf(settingsApi.specFftLength) : 0
                            onActivated: if (settingsApi)
                                settingsApi.specFftLength = model[currentIndex]
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("F0 Refinement")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.specF0Refinement : false
                            onToggled: if (settingsApi)
                                settingsApi.specF0Refinement = checked
                        }

                        Label {
                            text: qsTr("Use Log Scale")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.specUseLogScale : false
                            onToggled: if (settingsApi)
                                settingsApi.specUseLogScale = checked
                        }

                        Label {
                            text: qsTr("Color Scheme")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["Viridis", "Plasma", "Hot", "Cool"]
                            currentIndex: settingsApi ? settingsApi.specColorScheme : 0
                            onActivated: if (settingsApi)
                                settingsApi.specColorScheme = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Cepstrum Order")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.cepstrNumOrder.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.cepstrNumOrder = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 20

                background: Rectangle {
                    color: Theme.surfaceContainerLow(Material.theme)
                    radius: 16
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: qsTr("DP Calculation")
                        font.bold: true
                        font.pixelSize: 20
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 4
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        // Show DTW Alignment
                        Label {
                            text: qsTr("Show DTW Distances")
                            color: Theme.onSurface(Material.theme)
                            Layout.columnSpan: 1
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showDtwAlignment : true
                            onToggled: if (settingsApi)
                                settingsApi.showDtwAlignment = checked
                            Layout.columnSpan: 3
                        }

                        // Pitch
                        Label {
                            text: qsTr("Use Pitch")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUsePitch : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUsePitch = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUsePitch : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpPitchCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpPitchCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUsePitch : false
                        }

                        // Pitch Derivative
                        Label {
                            text: qsTr("Use Pitch Derivative")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUsePitchDerivative : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUsePitchDerivative = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUsePitchDerivative : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpPitchDerivativeCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpPitchDerivativeCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUsePitchDerivative : false
                        }

                        // Pitch Log
                        Label {
                            text: qsTr("Use Pitch Log")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUsePitchLog : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUsePitchLog = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUsePitchLog : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpPitchLogCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpPitchLogCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUsePitchLog : false
                        }

                        // Amplitude
                        Label {
                            text: qsTr("Use Amplitude")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUseAmplitude : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUseAmplitude = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseAmplitude : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpAmplitudeCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpAmplitudeCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUseAmplitude : false
                        }

                        // Amplitude Derivative
                        Label {
                            text: qsTr("Use Amp Derivative")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUseAmplitudeDerivative : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUseAmplitudeDerivative = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseAmplitudeDerivative : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpAmplitudeDerivativeCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpAmplitudeDerivativeCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUseAmplitudeDerivative : false
                        }

                        // Spectrum
                        Label {
                            text: qsTr("Use Spectrum")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUseSpectrum : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUseSpectrum = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseSpectrum : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpSpectrumCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpSpectrumCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUseSpectrum : false
                        }

                        // Cepstrum
                        Label {
                            text: qsTr("Use Cepstrum")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUseCepstrum : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUseCepstrum = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseCepstrum : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpCepstrumCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpCepstrumCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUseCepstrum : false
                        }
                    }
                }
            }
        }
    }
    Dialog {
        id: confirmationDialog
        title: qsTr("Delete user data")
        modal: true

        width: AppScale.px(root.width * 0.9)
        x: (AppScale.px(root.width) - width) / 2
        y: (AppScale.px(root.height) - height) / 2

        Label {
            text: qsTr("This action will permanently delete all user statistics and user records.\nThis cannot be undone. Are you sure?")
            color: Theme.onSurface(Material.theme)
            wrapMode: Text.Wrap
            font.pixelSize: AppScale.font(14)
            width: parent.width - AppScale.px(40)
        }

        footer: DialogButtonBox {
            background: Rectangle {
                color: "transparent"
            }
            Button {
                text: qsTr("Yes")
                font.pixelSize: AppScale.font(14)
                DialogButtonBox.buttonRole: DialogButtonBox.YesRole
            }
            Button {
                text: qsTr("No")
                font.pixelSize: AppScale.font(14)
                DialogButtonBox.buttonRole: DialogButtonBox.NoRole
            }
        }

        onAccepted: {
            if (settingsApi) {
                settingsApi.clearUserStatistics();
            }
        }
    }
}
