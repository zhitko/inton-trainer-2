import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.settings 1.0

Page {
    id: root
    title: qsTr("Settings")

    Material.theme: window.theme

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
                    border.color: Material.dividerColor
                    radius: 4
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: qsTr("General")
                        font.bold: true
                        font.pixelSize: 20
                        color: Material.accent
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Language")
                            color: Material.primaryTextColor
                        }
                        ComboBox {
                            model: ["en", "ru"]
                            currentIndex: model.indexOf(window.settingsApi.language)
                            onActivated: window.settingsApi.language = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Theme")
                            color: Material.primaryTextColor
                        }
                        ComboBox {
                            model: ["light", "dark", "system"]
                            currentIndex: model.indexOf(window.settingsApi.theme)
                            onActivated: window.settingsApi.theme = currentText
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true

                background: Rectangle {
                    color: "transparent"
                    border.color: Material.dividerColor
                    radius: 4
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: qsTr("Pitch")
                        font.bold: true
                        font.pixelSize: 20
                        color: Material.accent
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Algorithm")
                            color: Material.primaryTextColor
                        }
                        ComboBox {
                            model: ["RAPT"]
                            currentIndex: model.indexOf(window.settingsApi.algorithm)
                            onActivated: window.settingsApi.algorithm = currentText
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Frame Shift (ms)")
                            color: Material.primaryTextColor
                        }
                        TextField {
                            text: window.settingsApi.frameShift.toString()
                            onEditingFinished: window.settingsApi.frameShift = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Sample Rate (Hz)")
                            color: Material.primaryTextColor
                        }
                        TextField {
                            text: window.settingsApi.sampleRate.toString()
                            onEditingFinished: window.settingsApi.sampleRate = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Min F0 (Hz)")
                            color: Material.primaryTextColor
                        }
                        TextField {
                            text: window.settingsApi.minF0.toString()
                            onEditingFinished: window.settingsApi.minF0 = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Max F0 (Hz)")
                            color: Material.primaryTextColor
                        }
                        TextField {
                            text: window.settingsApi.maxF0.toString()
                            onEditingFinished: window.settingsApi.maxF0 = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Voicing Threshold")
                            color: Material.primaryTextColor
                        }
                        TextField {
                            text: window.settingsApi.voicingThreshold.toString()
                            onEditingFinished: window.settingsApi.voicingThreshold = parseFloat(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        Label {
                            text: qsTr("Pitch Normalization")
                            color: Material.primaryTextColor
                        }
                        ComboBox {
                            model: ["min_max", "mean"]
                            currentIndex: model.indexOf(window.settingsApi.pitchNormalization)
                            onActivated: window.settingsApi.pitchNormalization = currentText
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
