import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.settings 1.0

Page {
    id: root
    title: qsTr("Settings")

    readonly property var settingsApi: ApplicationWindow.window ? ApplicationWindow.window.settingsApi : null

    Material.theme: ApplicationWindow.window ? ApplicationWindow.window.theme : Material.Light

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20

            Frame {
                Layout.fillWidth: true

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
                            text: qsTr("Theme")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["light", "dark", "system"]
                            currentIndex: settingsApi ? model.indexOf(settingsApi.theme) : 0
                            onActivated: if (settingsApi)
                                settingsApi.theme = currentText
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
                    }
                }
            }

            Frame {
                Layout.fillWidth: true

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
                            checked: ApplicationWindow.window.settingsApi.showF0
                            onToggled: ApplicationWindow.window.settingsApi.showF0 = checked
                        }

                        Label {
                            text: qsTr("Show Processed Pitch (F0)")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.showProcessedPitch
                            onToggled: ApplicationWindow.window.settingsApi.showProcessedPitch = checked
                        }

                        Label {
                            text: qsTr("Show Log Pitch (LOG_F0)")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.showLogPitch
                            onToggled: ApplicationWindow.window.settingsApi.showLogPitch = checked
                        }

                        Label {
                            text: qsTr("Algorithm")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["RAPT"]
                            currentIndex: model.indexOf(ApplicationWindow.window.settingsApi.algorithm)
                            onActivated: ApplicationWindow.window.settingsApi.algorithm = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Frame Shift (ms)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.frameShift.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.frameShift = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Sample Rate (Hz)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.sampleRate.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.sampleRate = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Min F0 (Hz)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.minF0.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.minF0 = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Max F0 (Hz)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.maxF0.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.maxF0 = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Voicing Threshold")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.voicingThreshold.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.voicingThreshold = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Pitch Normalization")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["min_max", "mean"]
                            currentIndex: model.indexOf(ApplicationWindow.window.settingsApi.pitchNormalization)
                            onActivated: ApplicationWindow.window.settingsApi.pitchNormalization = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Pitch Interpolation")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["None", "Linear", "Cubic", "Akima", "Monotone"]
                            currentIndex: ApplicationWindow.window.settingsApi.pitchInterpolationType
                            onActivated: ApplicationWindow.window.settingsApi.pitchInterpolationType = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Pitch Smoothing")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["None", "MovingAverage", "Median", "Gaussian", "Spline"]
                            currentIndex: ApplicationWindow.window.settingsApi.pitchSmoothing
                            onActivated: ApplicationWindow.window.settingsApi.pitchSmoothing = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Smoothing Window Size")
                            color: Theme.onSurface(Material.theme)
                            visible: ApplicationWindow.window.settingsApi.pitchSmoothing !== 4 // Hide for Spline (4)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.pitchSmoothingWindowSize.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.pitchSmoothingWindowSize = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: ApplicationWindow.window.settingsApi.pitchSmoothing !== 4 // Hide for Spline (4)
                        }

                        Label {
                            text: qsTr("Gaussian Sigma")
                            color: Theme.onSurface(Material.theme)
                            visible: ApplicationWindow.window.settingsApi.pitchSmoothing === 3 // Show only for Gaussian (3)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.pitchGaussianSmoothingSigma.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.pitchGaussianSmoothingSigma = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: ApplicationWindow.window.settingsApi.pitchSmoothing === 3 // Show only for Gaussian (3)
                        }

                        Label {
                            text: qsTr("Spline Penalty")
                            color: Theme.onSurface(Material.theme)
                            visible: ApplicationWindow.window.settingsApi.pitchSmoothing === 4 // Show only for Spline (4)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.pitchSplineSmoothingPenalty.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.pitchSplineSmoothingPenalty = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: ApplicationWindow.window.settingsApi.pitchSmoothing === 4 // Show only for Spline (4)
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true

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
                            checked: ApplicationWindow.window.settingsApi.showAmplitude
                            onToggled: ApplicationWindow.window.settingsApi.showAmplitude = checked
                        }

                        Label {
                            text: qsTr("Show Amplitude Derivative")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.showAmplitudeDerivative
                            onToggled: ApplicationWindow.window.settingsApi.showAmplitudeDerivative = checked
                        }

                        Label {
                            text: qsTr("Window")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.amplitudeWindow.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.amplitudeWindow = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Shift")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.amplitudeShift.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.amplitudeShift = parseInt(text)
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
                            currentIndex: ApplicationWindow.window.settingsApi.amplitudeSmoothing
                            onActivated: ApplicationWindow.window.settingsApi.amplitudeSmoothing = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Smoothing Window Size")
                            color: Theme.onSurface(Material.theme)
                            visible: ApplicationWindow.window.settingsApi.amplitudeSmoothing !== 0 // Hide for None
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.amplitudeSmoothingWindowSize.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.amplitudeSmoothingWindowSize = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            visible: ApplicationWindow.window.settingsApi.amplitudeSmoothing !== 0 // Hide for None
                        }

                        Label {
                            text: qsTr("Gaussian Sigma")
                            color: Theme.onSurface(Material.theme)
                            visible: ApplicationWindow.window.settingsApi.amplitudeSmoothing === 3 // Show only for Gaussian (3)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.amplitudeGaussianSmoothingSigma.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.amplitudeGaussianSmoothingSigma = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: ApplicationWindow.window.settingsApi.amplitudeSmoothing === 3 // Show only for Gaussian (3)
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true

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
                            checked: ApplicationWindow.window.settingsApi.showSpectrum
                            onToggled: ApplicationWindow.window.settingsApi.showSpectrum = checked
                        }

                        Label {
                            text: qsTr("Show Cepstrum")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.showCepstrum
                            onToggled: ApplicationWindow.window.settingsApi.showCepstrum = checked
                        }

                        Label {
                            text: qsTr("FFT Length")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: [1024, 2048, 4096, 8192]
                            currentIndex: model.indexOf(ApplicationWindow.window.settingsApi.specFftLength)
                            onActivated: ApplicationWindow.window.settingsApi.specFftLength = model[currentIndex]
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("F0 Refinement")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.specF0Refinement
                            onToggled: ApplicationWindow.window.settingsApi.specF0Refinement = checked
                        }

                        Label {
                            text: qsTr("Use Log Scale")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.specUseLogScale
                            onToggled: ApplicationWindow.window.settingsApi.specUseLogScale = checked
                        }

                        Label {
                            text: qsTr("Color Scheme")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["Viridis", "Plasma", "Hot", "Cool"]
                            currentIndex: ApplicationWindow.window.settingsApi.specColorScheme
                            onActivated: ApplicationWindow.window.settingsApi.specColorScheme = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Cepstrum Order")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.cepstrNumOrder.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.cepstrNumOrder = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }
                    }
                }
            }
            Frame {
                Layout.fillWidth: true

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

                        // Pitch
                        Label {
                            text: qsTr("Use Pitch")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.dpUsePitch
                            onToggled: ApplicationWindow.window.settingsApi.dpUsePitch = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: ApplicationWindow.window.settingsApi.dpUsePitch
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.dpPitchCoef.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.dpPitchCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: ApplicationWindow.window.settingsApi.dpUsePitch
                        }

                        // Pitch Derivative
                        Label {
                            text: qsTr("Use Pitch Derivative")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.dpUsePitchDerivative
                            onToggled: ApplicationWindow.window.settingsApi.dpUsePitchDerivative = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: ApplicationWindow.window.settingsApi.dpUsePitchDerivative
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.dpPitchDerivativeCoef.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.dpPitchDerivativeCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: ApplicationWindow.window.settingsApi.dpUsePitchDerivative
                        }

                        // Pitch Log
                        Label {
                            text: qsTr("Use Pitch Log")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.dpUsePitchLog
                            onToggled: ApplicationWindow.window.settingsApi.dpUsePitchLog = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: ApplicationWindow.window.settingsApi.dpUsePitchLog
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.dpPitchLogCoef.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.dpPitchLogCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: ApplicationWindow.window.settingsApi.dpUsePitchLog
                        }

                        // Amplitude
                        Label {
                            text: qsTr("Use Amplitude")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.dpUseAmplitude
                            onToggled: ApplicationWindow.window.settingsApi.dpUseAmplitude = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: ApplicationWindow.window.settingsApi.dpUseAmplitude
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.dpAmplitudeCoef.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.dpAmplitudeCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: ApplicationWindow.window.settingsApi.dpUseAmplitude
                        }

                        // Amplitude Derivative
                        Label {
                            text: qsTr("Use Amp Derivative")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.dpUseAmplitudeDerivative
                            onToggled: ApplicationWindow.window.settingsApi.dpUseAmplitudeDerivative = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: ApplicationWindow.window.settingsApi.dpUseAmplitudeDerivative
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.dpAmplitudeDerivativeCoef.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.dpAmplitudeDerivativeCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: ApplicationWindow.window.settingsApi.dpUseAmplitudeDerivative
                        }

                        // Spectrum
                        Label {
                            text: qsTr("Use Spectrum")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.dpUseSpectrum
                            onToggled: ApplicationWindow.window.settingsApi.dpUseSpectrum = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: ApplicationWindow.window.settingsApi.dpUseSpectrum
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.dpSpectrumCoef.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.dpSpectrumCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: ApplicationWindow.window.settingsApi.dpUseSpectrum
                        }

                        // Cepstrum
                        Label {
                            text: qsTr("Use Cepstrum")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: ApplicationWindow.window.settingsApi.dpUseCepstrum
                            onToggled: ApplicationWindow.window.settingsApi.dpUseCepstrum = checked
                        }
                        Label {
                            text: qsTr("Coefficient")
                            color: Theme.onSurface(Material.theme)
                            enabled: ApplicationWindow.window.settingsApi.dpUseCepstrum
                        }
                        TextField {
                            text: ApplicationWindow.window.settingsApi.dpCepstrumCoef.toString()
                            onEditingFinished: ApplicationWindow.window.settingsApi.dpCepstrumCoef = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: ApplicationWindow.window.settingsApi.dpUseCepstrum
                        }
                    }
                }
            }
        }
    }
}
