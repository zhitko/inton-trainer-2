import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.audio 1.0
import "../utils"

// VAD Calibration dialog.
// Usage:
//   VadCalibrationDialog { id: myDialog; onCalibrationDone: function(threshold) { ... } }
//   myDialog.open()
//
// The dialog starts calibration automatically when opened and closes itself
// when calibration finishes. The resulting threshold is reported via the
// calibrationDone(threshold) signal so the caller can store it.

Dialog {
    id: root

    // Emitted when calibration finishes successfully.
    signal calibrationDoneEnergy(real threshold)
    signal calibrationDoneAutocorrelation(real threshold)

    title: qsTr("VAD Calibration")
    modal: true
    anchors.centerIn: parent
    width: 380
    closePolicy: Popup.NoAutoClose

    // Internal AudioApi — callers do not need to provide one.
    AudioApi {
        id: _calibrationAudioApi
        onCalibrationFinishedEnergy: function(threshold) {
            root.calibrationDoneEnergy(threshold);
            root.close();
        }
        onCalibrationFinishedAutocorrelation: function(threshold) {
            root.calibrationDoneAutocorrelation(threshold);
            root.close();
        }
    }

    contentItem: ColumnLayout {
        spacing: 16
        Label {
            text: qsTr("Please stay quiet for %1 seconds so the background noise level can be measured.").arg(window.settingsApi ? Math.round(window.settingsApi.vadCalibrationDurationMs / 1000) : 2)
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
        const method = window.settingsApi ? window.settingsApi.vadMethod : 0;
        if (method === 1) {  // 1: autocorr
            _calibrationAudioApi.calibrateVadAutocorrelation();
        } else {  // 0: energy, 2: hybrid (default to energy)
            _calibrationAudioApi.calibrateVadEnergy();
        }
    }
}
