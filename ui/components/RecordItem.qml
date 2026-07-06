import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import "../utils"

Item {
    id: root
    
    property string recordName: ""
    property string filePath: ""
    property int itemIndex: 0
    
    // Optional history properties
    property bool isHistory: false
    property string patternName: ""
    property string refFilePath: ""
    property double result: 0
    property string date: ""

    signal clicked
    signal deleted(string filePath)

    width: ListView.view ? ListView.view.width : 0
    height: 110

    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.margins: 4
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        radius: 12
        color: mouseArea.containsMouse ? Theme.surfaceContainerLow(Material.theme) : Theme.surface(Material.theme)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.12)
            blur: 0.34
            shadowVerticalOffset: 2
            shadowHorizontalOffset: 0
        }

        border.color: Theme.outline(Material.theme)
        border.width: 1

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
                text: Icons.faMicrophoneLines
                font.family: Icons.familySolid
                font.weight: Font.Black
                font.bold: true
                font.pixelSize: AppScale.fs(20)
                color: Theme.onPrimaryContainer(Material.theme)
            }
        }

        // Text Info (Center)
        ColumnLayout {
            anchors.left: iconCircle.right
            anchors.leftMargin: 16
            anchors.right: progressCircleContainer.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // Record name
            Text {
                text: root.recordName
                font.pixelSize: AppScale.fs(16)
                font.weight: 600
                color: Theme.onSurface(Material.theme)
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Pattern path (only show for history items)
            RowLayout {
                spacing: 4
                visible: root.isHistory && root.patternName !== ""
                Layout.maximumWidth: parent.width
                
                Text {
                    text: Icons.faMusic
                    font.family: Icons.familySolid
                    font.weight: Font.Black
                    font.pixelSize: AppScale.fs(12)
                    color: Theme.onSurfaceVariant(Material.theme)
                }
                Text {
                    text: root.patternName
                    font.pixelSize: AppScale.fs(12)
                    color: Theme.onSurfaceVariant(Material.theme)
                    opacity: 0.7
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            // Status text based on result
            Text {
                visible: root.isHistory
                text: {
                    if (root.result >= 90) return qsTr("Mastered");
                    else if (root.result >= 75) return qsTr("Excellent");
                    else if (root.result >= 60) return qsTr("Good");
                    else if (root.result >= 40) return qsTr("Needs work");
                    else if (root.result > 0) return qsTr("Poor");
                    else return "";
                }
                font.pixelSize: AppScale.fs(12)
                color: {
                    if (root.result >= 80) return "#4caf50";
                    else if (root.result >= 60) return "#ff9800";
                    else if (root.result > 0) return "#ef5350";
                    else return Theme.onSurfaceVariant(Material.theme);
                }
            }
        }

        // Progress Circle (Right side)
        Item {
            id: progressCircleContainer
            width: 64
            height: 64
            anchors.right: actionButtonsContainer.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: root.isHistory

            CircularProgress {
                id: progressCircle
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                lineWidth: 5
                progress: Math.min(root.result / 100, 1.0)
                color: {
                    if (root.result >= 80) return "#4caf50";
                    else if (root.result >= 60) return "#ff9800";
                    else if (root.result > 0) return "#ef5350";
                    else return Theme.primary(Material.theme);
                }
                backgroundColor: Theme.surfaceContainerHighest(Material.theme)

                Text {
                    anchors.centerIn: parent
                    text: Math.round(root.result) + "%"
                    font.pixelSize: AppScale.fs(14)
                    font.weight: Font.Bold
                    color: Theme.onSurfaceVariant(Material.theme)
                }
            }
        }

        // Action buttons (Play + Delete) on the far right
        RowLayout {
            id: actionButtonsContainer
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Play button
            PlayButton {
                id: playButton
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                file: root.filePath
                z: 2
            }

            // Delete button
            DeleteButton {
                id: deleteButton
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                file: root.filePath
                z: 2
                onFileDeleted: (deletedPath) => {
                    root.deleted(deletedPath);
                }
            }
        }

        MouseArea {
            id: mouseArea
            z: -1
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clicked();
            }
        }
    }
}
