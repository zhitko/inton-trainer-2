import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import by.intontrainer.statistics 1.0
import "../utils"

Item {
    id: root

    property string itemData: ""
    property int itemIndex: 0
    property string icon: Icons.faBook
    property string filePath: ""
    property bool isFolder: false
    property real avgScore: 0

    signal clicked

    StatisticsApi {
        id: statisticsApi
    }

    Component.onCompleted: {
        // Reload statistics when component becomes visible
        statisticsApi.reloadStatistics();
        // Force update of the UI by re-evaluating bindings
        updateStatistics();
    }

    onVisibleChanged: {
        if (visible) {
            // Reload statistics when component becomes visible (e.g., when going back)
            statisticsApi.reloadStatistics();
            updateStatistics();
        }
    }

    function updateStatistics() {
        let completeness = 0;
        let totalFiles = 0;
        let processedFiles = 0;
        let avgScoreVal = 0;

        if (root.isFolder) {
            console.log("Updating stats for folder:", root.filePath);
            let folderStats = statisticsApi.getAvgResultForFolder(root.filePath);
            completeness = folderStats.completeness;
            totalFiles = folderStats.totalFiles;
            processedFiles = folderStats.processedFiles;
            avgScoreVal = folderStats.avgResult;
            console.log("Calculated completeness for folder:", completeness, "processed:", processedFiles, "total:", totalFiles);
            percentageText.text = processedFiles + "/" + totalFiles + " (" + Math.round(completeness) + "% " + qsTr("Progress") + ")";
        } else {
            console.log("Updating stats for file:", root.filePath);
            avgScoreVal = statisticsApi.getAvgResultForFile(root.filePath);
            console.log("Calculated average result for file:", avgScoreVal);

            if (avgScoreVal >= 90)
                percentageText.text = qsTr("Mastered");
            else if (avgScoreVal >= 75)
                percentageText.text = qsTr("Excellent");
            else if (avgScoreVal >= 60)
                percentageText.text = qsTr("Good");
            else if (avgScoreVal >= 40)
                percentageText.text = qsTr("Needs work");
            else if (avgScoreVal > 0)
                percentageText.text = qsTr("Poor");
            else
                percentageText.text = qsTr("Not practiced yet");
        }
        root.avgScore = avgScoreVal;

        // Update main progress circle on the RIGHT with Average Score (Accuracy)
        progressCircle.progress = Math.min(avgScoreVal / 100, 1.0);

        // Update circle color based on score
        if (avgScoreVal >= 80)
            progressCircle.color = "#4CAF50";
        else
        // Green
        if (avgScoreVal >= 40)
            progressCircle.color = "#FF9800";
        else
        // Orange
        if (avgScoreVal > 0)
            progressCircle.color = "#F44336";
        else
            // Red
            progressCircle.color = Theme.primary(Material.theme);
    }

    width: ListView.view ? ListView.view.width : 0
    height: 100

    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.margins: 4 // Space for shadow
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        radius: 12 // MD3 medium shape token
        color: mouseArea.containsMouse ? Theme.surfaceContainerLow(Material.theme) : Theme.surface(Material.theme)

        // MD3 Elevation 1 - base elevation for cards
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.12)
            blur: 0.34
            shadowVerticalOffset: 2
            shadowHorizontalOffset: 0
        }

        // MD3 outline for surface containers
        border.color: Theme.outline(Material.theme)
        border.width: 1

        // MD3 State Layer - hover effect (8% opacity)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.onSurface(Material.theme)
            opacity: mouseArea.containsMouse ? 0.08 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Icon Circle (Left)
        Rectangle {
            id: iconCircle
            width: 48
            height: 48
            radius: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            color: {
                var colors = [Theme.primaryContainer(Material.theme), Theme.secondaryContainer(Material.theme), Theme.tertiaryContainer(Material.theme)];
                return colors[root.itemIndex % colors.length];
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Icons.familySolid
                font.pixelSize: 20
                color: Theme.onPrimaryContainer(Material.theme)
            }
        }

        // Text Info
        ColumnLayout {
            anchors.left: iconCircle.right
            anchors.leftMargin: 16
            anchors.right: statusIndicatorContainer.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: root.itemData // Folder name
                font.pixelSize: 18
                font.weight: 600
                color: Theme.onSurface(Material.theme)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 8
                Text {
                    text: Icons.faSquareCheck
                    font.family: Icons.familySolid
                    color: Theme.onSurfaceVariant(Material.theme)
                }
                Text {
                    id: percentageText
                    color: Theme.onSurfaceVariant(Material.theme)
                    font.pixelSize: 14
                }
            }
        }

        // Progress Indicator / Status
        Item {
            id: statusIndicatorContainer
            width: 64
            height: 64
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.verticalCenter: parent.verticalCenter

            Item {
                anchors.fill: parent

                CircularProgress {
                    id: progressCircle
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    lineWidth: 6
                    color: Theme.primary(Material.theme)
                    backgroundColor: Theme.surfaceContainerHighest(Material.theme)

                    Column {
                        anchors.centerIn: parent
                        Text {
                            text: qsTr("Accuracy")
                            font.pixelSize: 8
                            font.weight: Font.Medium
                            color: Theme.onSurfaceVariant(Material.theme)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            id: progressText
                            text: root.avgScore > 0 ? Math.round(root.avgScore) + "%" : "--"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: Theme.onSurfaceVariant(Material.theme)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clicked();
            }
        }
    }
}
