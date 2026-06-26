import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import by.intontrainer.statistics 1.0
import "../components"
import "../components/cards"
import "../utils"

Page {
    id: root
    title: " "

    readonly property var settingsApi: ApplicationWindow.window ? ApplicationWindow.window.settingsApi : null

    StatisticsApi {
        id: statisticsApi
    }

    Component.onCompleted: {
        // Force update of the UI by re-evaluating bindings
        updateStatistics();
    }

    onVisibleChanged: {
        if (visible) {
            // Reload statistics when page becomes visible (e.g., when going back)
            updateStatistics();
        }
    }

    function updateStatistics() {
        let stats = statisticsApi.getOverallStatistics();
        avgAccuracyBox.value = Math.round(stats.avgResult) + "%";
        totalResultsBox.value = Math.round(stats.wellTrainedFiles);
        filesCountBox.value = Math.round(stats.processedFiles) + " / " + Math.round(stats.totalFiles);

        // Update overall progress circle with completeness
        overallProgressCircle.progress = stats.completeness / 100;
        overallProgressText.text = Math.round(stats.completeness) + "%";
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: parent.width
        clip: true

        ColumnLayout {
            width: scrollView.width - 48
            x: 24
            // y: 24
            spacing: 24

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                // Layout.topMargin: 24
                Layout.bottomMargin: 26
                spacing: 14

                // Full-bleed hero: neutral surface; wave styled via MultiEffect (clarity, no tinted bg)
                Rectangle {
                    id: heroBanner
                    Layout.fillWidth: true
                    Layout.leftMargin: -24
                    Layout.rightMargin: -24
                    Layout.preferredHeight: titleColumn.implicitHeight + 48
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomLeftRadius: Theme.shapeLarge
                    bottomRightRadius: Theme.shapeLarge
                    clip: true
                    color: Theme.surface(Material.theme)

                    ColumnLayout {
                        id: titleColumn
                        anchors.centerIn: parent
                        width: parent.width - 32
                        spacing: 8

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: qsTr("Inton@Trainer 2.0")
                            font.weight: Font.Bold
                            font.pixelSize: AppScale.fs(30)
                            color: Theme.onSurface(Material.theme)
                        }

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: qsTr("Master Your Intonation")
                            font.pixelSize: AppScale.fs(17)
                            font.weight: Font.Medium
                            color: Theme.onSurfaceVariant(Material.theme)
                            opacity: 0.95
                        }
                    }
                }

                // MD3 Chip component for language selection
                Chip {
                    Layout.alignment: Qt.AlignHCenter
                    text: settingsApi ? settingsApi.languageTitle : ""
                    selected: true
                    icon: Icons.faGlobe
                    enabled: false
                }
            }

            // 2. Center Action Button with Waveform Visuals
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 160

                // Wave image rendered behind the button
                Image {
                    id: waveImage
                    anchors.fill: parent
                    visible: false
                    source: "qrc:/qt/qml/inton-trainer-2/res/images/wave.png"
                    fillMode: Image.PreserveAspectCrop
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: waveImage
                    opacity: Material.theme === Material.Dark ? 0.55 : 0.45
                    contrast: 0.38
                    brightness: Material.theme === Material.Dark ? 0.06 : -0.05
                    colorization: 0.64
                    colorizationColor: settingsApi ? settingsApi.primaryColor : "#6200ea"
                }

                StartTrainingButton {
                    anchors.centerIn: parent
                    text: qsTr("Start Training")
                    // If auto‑calibration is enabled, run the VAD calibration dialog first;
                    // otherwise navigate directly to the template categories page.
                    onClicked: {
                        if (window.settingsApi && window.settingsApi.autoCalibrate) {
                            homeVadCalibrationDialog.open();
                        } else {
                            stackView.push("TemplateCategoriesPage.qml");
                        }
                    }
                }

                // VAD calibration dialog – runs before entering training flow
                VadCalibrationDialog {
                    id: homeVadCalibrationDialog
                    onCalibrationDoneEnergy: function(threshold) {
                        if (window.settingsApi) {
                            window.settingsApi.vadThreshold = threshold;
                        }
                        // After successful calibration, navigate to the template categories page
                        stackView.push("TemplateCategoriesPage.qml");
                    }
                    onCalibrationDoneAutocorrelation: function(threshold) {
                        if (window.settingsApi) {
                            window.settingsApi.autoCorrThreshold = threshold;
                        }
                        // After successful calibration, navigate to the template categories page
                        stackView.push("TemplateCategoriesPage.qml");
                    }
                }
            }

            // 3. Stats Row
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                Layout.topMargin: 26
                spacing: 12

                StatBox {
                    id: avgAccuracyBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    icon: Icons.faChartLine
                    title: qsTr("Avg Accuracy:")
                }

                StatBox {
                    id: totalResultsBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    icon: Icons.faTrophy
                    title: qsTr("Mastered Files:")
                }

                StatBox {
                    id: filesCountBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    icon: Icons.faFolderOpen
                    title: qsTr("Files Trained:")
                }
            }

            // 4. Overall Progress
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                Layout.topMargin: 8

                CircularProgress {
                    id: overallProgressCircle
                    anchors.centerIn: parent
                    height: parent.height * 0.95
                    width: height
                    lineWidth: 14
                    progress: 0.85
                    color: Theme.primary(Material.theme)
                    backgroundColor: Theme.surfaceContainerHighest(Material.theme)

                    // Text inside
                    Column {
                        anchors.centerIn: parent

                        Text {
                            text: qsTr("Completion")
                            font.pixelSize: AppScale.fs(14)
                            color: Theme.onSurfaceVariant(Material.theme)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            id: overallProgressText
                            text: "85%"
                            font.pixelSize: AppScale.fs(36)
                            font.bold: true
                            color: Theme.onSurface(Material.theme)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
}
