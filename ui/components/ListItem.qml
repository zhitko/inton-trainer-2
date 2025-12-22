import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import "../utils"

Item {
    id: root

    property string itemData: ""
    property int itemIndex: 0
    property string icon: Icons.faBook

    signal clicked

    width: ListView.view ? ListView.view.width : 0
    height: 100

    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.margins: 4 // Space for shadow
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        radius: 16
        color: mouseArea.containsMouse ? Theme.surfaceContainerLow(Material.theme) : Theme.surface(Material.theme)
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.15)
            blur: 0.34
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }

        // Shadow effect (basic simulation with border for now or simplified)
        border.color: Theme.outlineVariant(Material.theme)
        border.width: 1

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
                    text: (Math.floor(Math.random() * 80) + 10) + "%" // Mock percentage
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
                visible: root.itemIndex === 0
                Text {
                    anchors.centerIn: parent
                    text: Icons.faCheck
                    font.family: Icons.familySolid
                    font.pixelSize: 48
                    color: Theme.primary(Material.theme)
                }
            }

            Item {
                anchors.fill: parent
                visible: root.itemIndex !== 0

                CircularProgress {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    lineWidth: 6
                    progress: Math.random() * 0.8 + 0.1
                    color: Theme.primary(Material.theme)
                    backgroundColor: Theme.surfaceContainerHighest(Material.theme)

                    Text {
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
