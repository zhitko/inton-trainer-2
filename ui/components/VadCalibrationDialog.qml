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
    signal calibrationDone(real threshold)

    title: qsTr("VAD Calibration")
    modal: true
    anchors.centerIn: parent
    width: 380
    closePolicy: Popup.NoAutoClose

    // Internal AudioApi — callers do not need to provide one.
    AudioApi {
        id: _calibrationAudioApi
        onCalibrationFinished: function(threshold) {
            root.calibrationDone(threshold);
            root.close();
        }
    }

    contentItem: ColumnLayout {
        spacing: 16
        Label {
            text: qsTr("Please stay quiet for 2 seconds so the background noise level can be measured.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 15
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
        _calibrationAudioApi.calibrateVad();
    }
}
