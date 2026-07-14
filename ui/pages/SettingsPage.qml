import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.settings 1.0
import "../utils"
import "../components"

Page {
    id: root
    title: qsTr("Settings")

    readonly property var settingsApi: ApplicationWindow.window ? ApplicationWindow.window.settingsApi : null

    // Helper function to parse float values with support for both "." and "," as decimal separators
    function parseDoubleValue(text) {
        // Replace comma with dot and parse as float
        return parseFloat(text.replace(",", "."));
    }

    // VAD Calibration dialog (extracted component)
    VadCalibrationDialog {
        id: vadCalibrationDialog
        onCalibrationDoneEnergy: function (threshold) {
            if (settingsApi) {
                settingsApi.vadThreshold = threshold;
            }
        }
        onCalibrationDoneAutocorrelation: function (threshold) {
            if (settingsApi) {
                settingsApi.autoCorrThreshold = threshold;
            }
        }
    }

    Material.theme: ApplicationWindow.window ? ApplicationWindow.window.theme : Material.Light

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.vertical.policy: (window.settingsApi && !window.settingsApi.showNavigationMenu) ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded

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
                        font.pixelSize: AppScale.fs(20)
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

                        Label {
                            text: qsTr("Font Size")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            id: fontSizeCombo
                            textRole: "name"
                            valueRole: "value"
                            model: [
                                { "name": qsTr("Small"), "value": 1.0 },
                                { "name": qsTr("Normal"), "value": 1.3 },
                                { "name": qsTr("Big"), "value": 1.6 }
                            ]
                            currentIndex: {
                                if (!settingsApi) return 0;
                                let val = settingsApi.fontSizeMultiplier;
                                if (Math.abs(val - 1.3) < 0.1) return 1;
                                if (Math.abs(val - 1.6) < 0.1) return 2;
                                return 0;
                            }
                            onActivated: if (settingsApi)
                                settingsApi.fontSizeMultiplier = model[index].value
                            Layout.fillWidth: true
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
                Layout.margins: 20

                background: Rectangle {
                    color: Theme.surfaceContainerLow(Material.theme)
                    radius: 16
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: qsTr("Automated Recording (VAD)")
                        font.bold: true
                        font.pixelSize: AppScale.fs(20)
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Enable \"Guided\" training mode")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            id: guidedModeSwitch
                            checked: settingsApi ? settingsApi.guidedModeEnabled : true
                            onToggled: if (settingsApi) settingsApi.guidedModeEnabled = checked
                        }

                        Label {
                            text: qsTr("Listen Window Timeout (ms)")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.guidedModeEnabled : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.guidedListenTimeoutMs.toString() : "4000"
                            onEditingFinished: if (settingsApi)
                                settingsApi.guidedListenTimeoutMs = parseInt(text)
                            enabled: settingsApi ? settingsApi.guidedModeEnabled : false
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Post-Playback Delay (ms)")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.guidedModeEnabled : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.guidedPrePlayListenDelayMs.toString() : "150"
                            onEditingFinished: if (settingsApi)
                                settingsApi.guidedPrePlayListenDelayMs = parseInt(text)
                            enabled: settingsApi ? settingsApi.guidedModeEnabled : false
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Auto Stop Recording")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.autoStopRecording : true
                            onToggled: if (settingsApi)
                                settingsApi.autoStopRecording = checked
                        }

                        Label {
                            text: qsTr("Autocalibrate before recording")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.autoCalibrate : true
                            onToggled: if (settingsApi)
                                settingsApi.autoCalibrate = checked
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }
                        Label {
                            text: qsTr("VAD Method")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }
                        ComboBox {
                            model: [qsTr("Energy"), qsTr("Autocorrelation"), qsTr("Hybrid AND"), qsTr("Hybrid OR")]
                            currentIndex: settingsApi ? settingsApi.vadMethod : 0
                            onActivated: if (settingsApi)
                                settingsApi.vadMethod = currentIndex
                            Layout.fillWidth: true
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }

                        Label {
                            text: qsTr("Calibration Duration (ms)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            id: vadCalibrationDurationField
                            text: settingsApi ? settingsApi.vadCalibrationDurationMs.toString() : 2000
                            onEditingFinished: if (settingsApi)
                                settingsApi.vadCalibrationDurationMs = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }

                        Label {
                            text: qsTr("Silence Duration (ms)")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            id: silenceDurationField
                            text: settingsApi ? settingsApi.autoStopSilenceDuration.toString() : 2000
                            onEditingFinished: if (settingsApi)
                                settingsApi.autoStopSilenceDuration = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }

                        Label {
                            text: qsTr("Minimum Record Length (%)")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }
                        TextField {
                            id: minimumRecordLengthField
                            text: settingsApi ? (settingsApi.minimumRecordLengthPercent * 100).toFixed(0) : 100
                            onEditingFinished: if (settingsApi)
                                settingsApi.minimumRecordLengthPercent = parseDoubleValue(text) / 100.0
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                        }

                        Label {
                            text: qsTr("Energy Threshold (Pe)")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 0 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true
                        }

                        TextField {
                            id: vadThresholdField
                            text: settingsApi ? settingsApi.vadThreshold.toFixed(1) : 50000.0
                            onEditingFinished: if (settingsApi)
                                settingsApi.vadThreshold = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 0 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true

                            Connections {
                                target: settingsApi
                                function onVadThresholdChanged() {
                                    if (!vadThresholdField.activeFocus)
                                        vadThresholdField.text = settingsApi.vadThreshold.toFixed(1);
                                }
                            }
                        }

                        Button {
                            id: calibrateBtn
                            text: qsTr("Calibrate")
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            enabled: settingsApi ? settingsApi.autoStopRecording : false

                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Measure background noise for 2 seconds to set optimal threshold")

                            onClicked: vadCalibrationDialog.open()
                            visible: settingsApi ? (settingsApi.vadMethod === 0 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true

                            background: Rectangle {
                                radius: 8
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: calibrateBtn.hovered ? Qt.lighter(Theme.primary(Material.theme), 1.1) : Theme.primary(Material.theme)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: calibrateBtn.hovered ? Theme.primary(Material.theme) : Qt.darker(Theme.primary(Material.theme), 1.15)
                                    }
                                }
                                opacity: calibrateBtn.enabled ? 1.0 : 0.4
                            }

                            contentItem: Text {
                                text: calibrateBtn.text
                                color: Theme.onPrimary(Material.theme)
                                font.pixelSize: AppScale.fs(13)
                                font.weight: 600
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Label {
                            text: qsTr("Autocorr. Threshold")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true
                        }

                        TextField {
                            id: autoCorrThresholdField
                            text: settingsApi ? settingsApi.autoCorrThreshold.toFixed(2) : 0.30
                            onEditingFinished: if (settingsApi)
                                settingsApi.autoCorrThreshold = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true

                            Connections {
                                target: settingsApi
                                function onAutoCorrThresholdChanged() {
                                    if (!autoCorrThresholdField.activeFocus)
                                        autoCorrThresholdField.text = settingsApi.autoCorrThreshold.toFixed(2);
                                }
                            }
                        }

                        Label {
                            text: qsTr("Autocorr. Threshold K:")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true
                        }

                        TextField {
                            id: autoCorrThresholdKField
                            text: settingsApi ? settingsApi.autoCorrThresholdK.toFixed(2) : "1.00"
                            onEditingFinished: if (settingsApi)
                                settingsApi.autoCorrThresholdK = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true

                            Connections {
                                target: settingsApi
                                function onAutoCorrThresholdKChanged() {
                                    if (!autoCorrThresholdKField.activeFocus)
                                        autoCorrThresholdKField.text = settingsApi.autoCorrThresholdK.toFixed(2);
                                }
                            }
                        }

                        Label {
                            text: qsTr("Autocorr Min F0 (Hz)")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true
                        }

                        TextField {
                            id: autoCorrMinF0Field
                            text: settingsApi ? settingsApi.autoCorrMinF0.toFixed(0) : 80
                            onEditingFinished: if (settingsApi)
                                settingsApi.autoCorrMinF0 = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true

                            Connections {
                                target: settingsApi
                                function onAutoCorrMinF0Changed() {
                                    if (!autoCorrMinF0Field.activeFocus)
                                        autoCorrMinF0Field.text = settingsApi.autoCorrMinF0.toFixed(0);
                                }
                            }
                        }

                        Label {
                            text: qsTr("Autocorr Max F0 (Hz)")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true
                        }

                        TextField {
                            id: autoCorrMaxF0Field
                            text: settingsApi ? settingsApi.autoCorrMaxF0.toFixed(0) : 300
                            onEditingFinished: if (settingsApi)
                                settingsApi.autoCorrMaxF0 = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.autoStopRecording : false
                            visible: settingsApi ? (settingsApi.vadMethod === 1 || settingsApi.vadMethod === 2 || settingsApi.vadMethod === 3) : true

                            Connections {
                                target: settingsApi
                                function onAutoCorrMaxF0Changed() {
                                    if (!autoCorrMaxF0Field.activeFocus)
                                        autoCorrMaxF0Field.text = settingsApi.autoCorrMaxF0.toFixed(0);
                                }
                            }
                        }

                        Button {
                            id: calibrateAutoCorrBtn
                            text: qsTr("Calibrate")
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            enabled: settingsApi ? settingsApi.autoStopRecording : false

                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Measure background noise for 2 seconds to set optimal threshold")

                            onClicked: vadCalibrationDialog.open()
                            visible: settingsApi ? (settingsApi.vadMethod === 1) : true

                            background: Rectangle {
                                radius: 8
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: calibrateAutoCorrBtn.hovered ? Qt.lighter(Theme.primary(Material.theme), 1.1) : Theme.primary(Material.theme)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: calibrateAutoCorrBtn.hovered ? Theme.primary(Material.theme) : Qt.darker(Theme.primary(Material.theme), 1.15)
                                    }
                                }
                                opacity: calibrateAutoCorrBtn.enabled ? 1.0 : 0.4
                            }

                            contentItem: Text {
                                text: calibrateAutoCorrBtn.text
                                color: Theme.onPrimary(Material.theme)
                                font.pixelSize: AppScale.fs(13)
                                font.weight: 600
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Label {
                            text: qsTr("Show A(n)")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showVadA : false
                            onToggled: if (settingsApi)
                                settingsApi.showVadA = checked
                        }

                        Label {
                            text: qsTr("Show U(n)")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showVadU : false
                            onToggled: if (settingsApi)
                                settingsApi.showVadU = checked
                        }

                        Label {
                            text: qsTr("Show V(n)")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showVadV : false
                            onToggled: if (settingsApi)
                                settingsApi.showVadV = checked
                        }

                        Label {
                            text: qsTr("Show Corr.")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showVadCorr : false
                            onToggled: if (settingsApi)
                                settingsApi.showVadCorr = checked
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
                        font.pixelSize: AppScale.fs(20)
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
                            text: qsTr("Use Only N")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.useOnlyN : true
                            onToggled: if (settingsApi)
                                settingsApi.useOnlyN = checked
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
                                settingsApi.frameShift = parseDoubleValue(text)
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
                                settingsApi.sampleRate = parseDoubleValue(text)
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
                                settingsApi.minF0 = parseDoubleValue(text)
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
                                settingsApi.maxF0 = parseDoubleValue(text)
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
                                settingsApi.voicingThreshold = parseDoubleValue(text)
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
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Gaussian Sigma")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.pitchSmoothing === 3 : false // Show only for Gaussian (3)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.pitchGaussianSmoothingSigma.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.pitchGaussianSmoothingSigma = parseDoubleValue(text)
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
                                settingsApi.pitchSplineSmoothingPenalty = parseDoubleValue(text)
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

                    Label {
                        text: qsTr("Pitch Log")
                        font.bold: true
                        font.pixelSize: AppScale.fs(20)
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Smoothing Window Size")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.pitchLogSmoothingWindowSize.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.pitchLogSmoothingWindowSize = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Moving Average Size")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.pitchLogSmoothingMovingAverageSize.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.pitchLogSmoothingMovingAverageSize = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        Label {
                            text: qsTr("Transform to Binary")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.transformPitchLogToBinary : false
                            onToggled: if (settingsApi)
                                settingsApi.transformPitchLogToBinary = checked
                        }

                        Label {
                            text: qsTr("Binary Threshold")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.transformPitchLogToBinary : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.transformPitchLogThreshold.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.transformPitchLogThreshold = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.transformPitchLogToBinary : false
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
                        text: qsTr("UMP")
                        font.bold: true
                        font.pixelSize: AppScale.fs(20)
                        color: Theme.primary(Material.theme)
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Show UMP")
                            color: Theme.onSurface(Material.theme)
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.showUMP : true
                            onToggled: if (settingsApi)
                                settingsApi.showUMP = checked
                        }

                        Label {
                            text: qsTr("Smoothing")
                            color: Theme.onSurface(Material.theme)
                        }
                        ComboBox {
                            model: ["None", "MovingAverage", "Median", "Gaussian", "Spline"]
                            currentIndex: settingsApi ? settingsApi.umpSmoothing : 0
                            onActivated: if (settingsApi)
                                settingsApi.umpSmoothing = currentIndex
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Smoothing Window Size")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.umpSmoothing !== 0 && settingsApi.umpSmoothing !== 4 : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.umpSmoothingWindowSize.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.umpSmoothingWindowSize = parseInt(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            visible: settingsApi ? settingsApi.umpSmoothing !== 0 && settingsApi.umpSmoothing !== 4 : false
                        }

                        Label {
                            text: qsTr("Gaussian Sigma")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.umpSmoothing === 3 : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.umpGaussianSmoothingSigma.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.umpGaussianSmoothingSigma = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: settingsApi ? settingsApi.umpSmoothing === 3 : false
                        }

                        Label {
                            text: qsTr("Spline Penalty")
                            color: Theme.onSurface(Material.theme)
                            visible: settingsApi ? settingsApi.umpSmoothing === 4 : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.umpSplineSmoothingPenalty.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.umpSplineSmoothingPenalty = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            visible: settingsApi ? settingsApi.umpSmoothing === 4 : false
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
                        font.pixelSize: AppScale.fs(20)
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
                                settingsApi.amplitudeGaussianSmoothingSigma = parseDoubleValue(text)
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
                        font.pixelSize: AppScale.fs(20)
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
                        font.pixelSize: AppScale.fs(20)
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

                        // Fixed start/end DTW (morph aligned sequences)
                        Label {
                            text: qsTr("Fixed start/end")
                            color: Theme.onSurface(Material.theme)
                            Layout.columnSpan: 1
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUseFixedStartEndDP : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUseFixedStartEndDP = checked
                            Layout.columnSpan: 3
                        }

                        // Pitch Log as Mask
                        Label {
                            text: qsTr("Use Pitch Log as Mask")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUsePitchLog : false
                        }
                        Switch {
                            checked: settingsApi ? settingsApi.dpUsePitchLogAsMask : false
                            onToggled: if (settingsApi)
                                settingsApi.dpUsePitchLogAsMask = checked
                            enabled: settingsApi ? settingsApi.dpUsePitchLog : false
                            Layout.columnSpan: 3
                        }

                        // DTW Distance Limit
                        Label {
                            text: qsTr("DTW Distance Limit")
                            color: Theme.onSurface(Material.theme)
                            Layout.columnSpan: 1
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dtwDistanceLimit.toString() : "100"
                            onEditingFinished: if (settingsApi)
                                settingsApi.dtwDistanceLimit = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
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
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUsePitch : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpPitchCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpPitchCoef = parseDoubleValue(text)
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
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUsePitchDerivative : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpPitchDerivativeCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpPitchDerivativeCoef = parseDoubleValue(text)
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
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUsePitchLog : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpPitchLogCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpPitchLogCoef = parseDoubleValue(text)
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
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseAmplitude : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpAmplitudeCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpAmplitudeCoef = parseDoubleValue(text)
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
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseAmplitudeDerivative : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpAmplitudeDerivativeCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpAmplitudeDerivativeCoef = parseDoubleValue(text)
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
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseSpectrum : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpSpectrumCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpSpectrumCoef = parseDoubleValue(text)
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
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                            enabled: settingsApi ? settingsApi.dpUseCepstrum : false
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpCepstrumCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpCepstrumCoef = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                            enabled: settingsApi ? settingsApi.dpUseCepstrum : false
                        }

                        // Match Coefficient
                        Label {
                            text: qsTr("Match Coefficient")
                            color: Theme.onSurface(Material.theme)
                        }
                        Label {
                            text: ""
                            enabled: false
                        }
                        Label {
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpMatchCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpMatchCoef = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        // Insertion Coefficient
                        Label {
                            text: qsTr("Insertion Coefficient")
                            color: Theme.onSurface(Material.theme)
                        }
                        Label {
                            text: ""
                            enabled: false
                        }
                        Label {
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpInsertionCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpInsertionCoef = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        // Deletion Coefficient
                        Label {
                            text: qsTr("Deletion Coefficient")
                            color: Theme.onSurface(Material.theme)
                        }
                        Label {
                            text: ""
                            enabled: false
                        }
                        Label {
                            text: qsTr("Coeff.")
                            color: Theme.onSurface(Material.theme)
                        }
                        TextField {
                            text: settingsApi ? settingsApi.dpDeletionCoef.toString() : ""
                            onEditingFinished: if (settingsApi)
                                settingsApi.dpDeletionCoef = parseDoubleValue(text)
                            Layout.fillWidth: true
                            selectByMouse: true
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
            font.pixelSize: AppScale.fs(14)
            width: parent.width - AppScale.px(40)
        }

        footer: DialogButtonBox {
            background: Rectangle {
                color: "transparent"
            }
            Button {
                text: qsTr("Yes")
                font.pixelSize: AppScale.fs(14)
                DialogButtonBox.buttonRole: DialogButtonBox.YesRole
            }
            Button {
                text: qsTr("No")
                font.pixelSize: AppScale.fs(14)
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
