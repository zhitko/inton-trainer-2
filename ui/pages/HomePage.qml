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
    padding: 0

    readonly property var settingsApi: ApplicationWindow.window ? ApplicationWindow.window.settingsApi : null
    readonly property bool compactHome: AppScale.isCompact
    readonly property bool shortHome: AppScale.isShort

    StatisticsApi {
        id: statisticsApi
    }

    Component.onCompleted: {
        updateStatistics();
    }

    onVisibleChanged: {
        if (visible) {
            updateStatistics();
        }
    }

    function updateStatistics() {
        let stats = statisticsApi.getOverallStatistics();
        avgAccuracyBox.value = Math.round(stats.avgResult) + "%";
        totalResultsBox.value = Math.round(stats.wellTrainedFiles);
        filesCountBox.value = Math.round(stats.processedFiles) + " / " + Math.round(stats.totalFiles);

        overallProgressCircle.progress = stats.completeness / 100;
        overallProgressText.text = Math.round(stats.completeness) + "%";
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: (window.settingsApi && !window.settingsApi.showNavigationMenu)
                                   ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: Math.max(0, scrollView.availableWidth - AppScale.pagePadding * 2)
            height: Math.max(implicitHeight, scrollView.availableHeight)
            x: AppScale.pagePadding
            spacing: root.shortHome ? 8 : AppScale.pageSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: root.shortHome ? 4 : (root.compactHome ? 8 : 16)
                spacing: root.shortHome ? 4 : 8

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: qsTr("Inton@Trainer 2.0")
                    font.weight: Font.Bold
                    font.pixelSize: AppScale.fs(root.compactHome ? 24 : 30)
                    color: Theme.onSurface(Material.theme)
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: qsTr("Master Your Intonation")
                    font.pixelSize: AppScale.fs(root.shortHome ? 15 : 17)
                    font.weight: Font.Medium
                    color: Theme.onSurfaceVariant(Material.theme)
                    opacity: 0.95
                }

                Chip {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: root.shortHome ? 4 : 8
                    text: settingsApi ? settingsApi.languageTitle : ""
                    selected: true
                    icon: Icons.faGlobe
                    enabled: false
                }
            }

            Item {
                id: startSlot
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: root.compactHome ? 112 : 140
                Layout.preferredHeight: root.compactHome ? 168 : 200
                Layout.maximumHeight: 260
                clip: true

                Image {
                    id: waveImage
                    visible: false
                    anchors.centerIn: parent
                    // Bitmap is 628×100. Never stretch taller (or wider) than native
                    // size — vertical fill was what made it look fuzzy.
                    readonly property real nativeW: implicitWidth > 0 ? implicitWidth : 628
                    readonly property real nativeH: implicitHeight > 0 ? implicitHeight : 100
                    width: Math.min(parent.width, nativeW)
                    height: width * nativeH / nativeW
                    source: "qrc:/qt/qml/inton-trainer-2/res/images/wave.png"
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }

                MultiEffect {
                    anchors.fill: waveImage
                    source: waveImage
                    opacity: Material.theme === Material.Dark ? 0.55 : 0.45
                    contrast: 0.38
                    brightness: Material.theme === Material.Dark ? 0.06 : -0.05
                    colorization: 0.64
                    colorizationColor: settingsApi ? settingsApi.primaryColor : "#6200ea"
                }

                StartTrainingButton {
                    anchors.fill: parent
                    text: qsTr("Start Training")
                    onClicked: {
                        if (window.settingsApi && window.settingsApi.autoCalibrate) {
                            homeVadCalibrationDialog.open();
                        } else {
                            stackView.push("TemplateCategoriesPage.qml");
                        }
                    }
                }

                VadCalibrationDialog {
                    id: homeVadCalibrationDialog
                    onCalibrationDoneEnergy: function(threshold) {
                        if (window.settingsApi) {
                            window.settingsApi.vadThreshold = threshold;
                        }
                        stackView.push("TemplateCategoriesPage.qml");
                    }
                    onCalibrationDoneAutocorrelation: function(threshold) {
                        if (window.settingsApi) {
                            window.settingsApi.autoCorrThreshold = threshold;
                        }
                        stackView.push("TemplateCategoriesPage.qml");
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compactHome ? 88 : 110
                Layout.maximumHeight: 120
                spacing: root.compactHome ? 8 : 12

                StatBox {
                    id: avgAccuracyBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    icon: Icons.faChartLine
                    title: qsTr("Avg Accuracy:")
                }

                StatBox {
                    id: totalResultsBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    icon: Icons.faTrophy
                    title: qsTr("Mastered Files:")
                }

                StatBox {
                    id: filesCountBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    icon: Icons.faFolderOpen
                    title: qsTr("Files Trained:")
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: root.compactHome ? 96 : 120
                Layout.preferredHeight: root.compactHome ? 132 : 180
                Layout.maximumHeight: 220
                Layout.bottomMargin: AppScale.pagePadding

                CircularProgress {
                    id: overallProgressCircle
                    readonly property real ringSize: Math.min(parent.height, parent.width * 0.42, 200)
                    anchors.centerIn: parent
                    width: ringSize
                    height: ringSize
                    lineWidth: Math.max(8, Math.round(ringSize * 0.08))
                    progress: 0.85
                    color: Theme.primary(Material.theme)
                    backgroundColor: Theme.surfaceContainerHighest(Material.theme)

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: qsTr("Completion")
                            font.pixelSize: AppScale.fs(overallProgressCircle.ringSize < 130 ? 12 : 14)
                            color: Theme.onSurfaceVariant(Material.theme)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            id: overallProgressText
                            text: "85%"
                            font.pixelSize: AppScale.fs(overallProgressCircle.ringSize < 130 ? 28 : 36)
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
