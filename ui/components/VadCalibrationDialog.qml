import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.audio 1.0
import "../utils"

// VAD Calibration dialog.
// Usage:
//   VadCalibrationDialog { id: myDialog; onCalibrationDone: { ... } }
//   myDialog.open()
//
// The dialog starts calibration automatically when opened and closes itself
// when calibration finishes. Thresholds are saved through SettingsApi before
// calibrationDone() is emitted once (including for hybrid calibration).

Dialog {
    id: root

    signal calibrationDone()
    property int calibrationMethod: 0

    function startCalibration() {
        if (calibrationMethod === 1)
            _calibrationAudioApi.calibrateVadAutocorrelation();
        else
            _calibrationAudioApi.calibrateVadEnergy();
    }

    function finishCalibration() {
        root.close();
        root.calibrationDone();
    }

    title: qsTr("VAD Calibration")
    modal: true
    anchors.centerIn: parent
    width: 380
    closePolicy: Popup.NoAutoClose

    // Internal AudioApi — callers do not need to provide one.
    AudioApi {
        id: _calibrationAudioApi
        onCalibrationFinishedEnergy: function(threshold) {
            if (window.settingsApi)
                window.settingsApi.vadThreshold = threshold;
            if (root.calibrationMethod >= 2) {
                // Both detectors participate in hybrid decisions.
                Qt.callLater(function() {
                    _calibrationAudioApi.calibrateVadAutocorrelation();
                });
            } else {
                root.finishCalibration();
            }
        }
        onCalibrationEnergyGateChanged: function(threshold) {
            if (window.settingsApi)
                window.settingsApi.autoCorrEnergyThreshold = threshold;
        }
        onCalibrationFinishedAutocorrelation: function(threshold) {
            if (window.settingsApi)
                window.settingsApi.autoCorrThreshold = threshold;
            root.finishCalibration();
        }
        onPermissionResultReceived: function(granted) {
            if (granted) {
                // Retry calibration after permission granted
                root.startCalibration();
            } else {
                Logger.warning("Microphone permission denied — cannot calibrate");
                root.close();
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 16
        Label {
            text: qsTr("Please stay quiet for %1 seconds so the background noise level can be measured.").arg(Math.ceil((window.settingsApi ? window.settingsApi.vadCalibrationDurationMs : 2000) * (root.calibrationMethod >= 2 ? 2 : 1) / 1000))
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: AppScale.fs(15)
        }
        // Animated dots to show progress
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Repeater {
                model: 3
                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.primary(Material.theme)
                    SequentialAnimation on opacity {
                        running: root.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.2; to: 1.0; duration: 400 }
                        NumberAnimation { from: 1.0; to: 0.2; duration: 400 }
                        PauseAnimation { duration: index * 200 }
                    }
                }
            }
        }
    }

    onOpened: {
        calibrationMethod = window.settingsApi ? window.settingsApi.vadMethod : 0;
        // Request microphone permission first (no-op on desktop)
        if (!_calibrationAudioApi.requestAudioPermission()) {
            // Permission request is pending — will retry calibration in
            // onPermissionResultReceived callback
            return;
        }
        startCalibration();
    }
}
