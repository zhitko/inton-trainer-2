import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.settings 1.0

Page {
    id: root
    title: qsTr("Settings")

    Material.theme: ApplicationWindow.window.theme

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
                    color: "transparent"
                    border.color: Theme.outlineVariant(Material.theme)
                    radius: 8
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
                            currentIndex: model.indexOf(ApplicationWindow.window.settingsApi.language)
                            onActivated: ApplicationWindow.window.settingsApi.language = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Theme")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["light", "dark", "system"]
                            currentIndex: model.indexOf(ApplicationWindow.window.settingsApi.theme)
                            onActivated: ApplicationWindow.window.settingsApi.theme = currentText
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true

                background: Rectangle {
                    color: "transparent"
                    border.color: Theme.outlineVariant(Material.theme)
                    radius: 8
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
        }
    }
}
