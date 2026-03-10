import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
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
        // Reload statistics when page becomes visible
        statisticsApi.reloadStatistics();
        // Force update of the UI by re-evaluating bindings
        updateStatistics();
    }

    onVisibleChanged: {
        if (visible) {
            // Reload statistics when page becomes visible (e.g., when going back)
            statisticsApi.reloadStatistics();
            updateStatistics();
        }
    }

    function updateStatistics() {
        let stats = statisticsApi.getOverallStatistics();
        avgAccuracyBox.value = Math.round(stats.avgResult) + "%";
        totalResultsBox.value = Math.round(stats.totalResults);
        filesCountBox.value = Math.round(stats.filesCount);

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
            y: 24
            spacing: 24

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                Layout.bottomMargin: 40
                spacing: 12

                Label {
                    text: qsTr("Inton@Trainer 2.0")
                    font.weight: Font.Bold
                    font.pixelSize: 32
                    color: Theme.primary(Material.theme)
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("Master Your Intonation")
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: Theme.onSurfaceVariant(Material.theme)
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.8
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
            StartTrainingButton {
                text: qsTr("Start Training")
                onClicked: stackView.push("CategoriesPage.qml")
            }

            // 3. Stats Row
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 85
                Layout.topMargin: 40
                spacing: 12

                StatBox {
                    id: avgAccuracyBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    icon: Icons.faChartLine
                    title: qsTr("Avg Accuracy:")
                }

                StatBox {
                    id: totalResultsBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    icon: Icons.faCheckCircle
                    title: qsTr("Total Results:")
                }

                StatBox {
                    id: filesCountBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    icon: Icons.faFolderOpen
                    title: qsTr("Files Trained:")
                }
            }

            // 4. Overall Progress
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 180

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
                            font.pixelSize: 14
                            color: Theme.onSurfaceVariant(Material.theme)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            id: overallProgressText
                            text: "85%"
                            font.pixelSize: 36
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
