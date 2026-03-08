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
        let stats = 0;
        // Update percentage text with fresh statistics
        if (root.isFolder) {
            console.log("Updating stats for folder:", root.filePath);
            stats = statisticsApi.getAvgResultForFolder(root.filePath).completeness;
            console.log("Calculated completeness for folder:", stats);
        } else {
            console.log("Updating stats for file:", root.filePath);
            stats = statisticsApi.getAvgResultForFile(root.filePath);
            console.log("Calculated average result for file:", stats);
        }
        percentageText.text = Math.round(stats) + "%";
        
        // Update progress circle
        progressCircle.progress = Math.min(stats / 100, 1.0);
        progressText.text = Math.round(stats) + "%";
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

        // Icon Circle
        Rectangle {
            id: iconCircle
            width: 48
            height: 48
            radius: 24
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            color: {
                // Mocking different colors based on index or content
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

                    Text {
                        id: progressText
                        anchors.centerIn: parent
                        text: Math.round(parent.progress * 100) + "%"
                        font.pixelSize: 14
                        color: Theme.onSurfaceVariant(Material.theme)
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
