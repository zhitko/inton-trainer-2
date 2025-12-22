import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import "../components"
import "../components/cards"

Page {
    id: root
    title: qsTr("Home")

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

            // 1. Header Section
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Label {
                    text: qsTr("Inton@Trainer 2.0")
                    font.bold: true
                    font.pixelSize: 28
                    color: Theme.onSurface(Material.theme)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: qsTr("American English")
                    font.pixelSize: 16
                    color: Theme.onSurfaceVariant(Material.theme)
                    anchors.horizontalCenter: parent.horizontalCenter
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
                Layout.preferredHeight: 100
                spacing: 16

                StatBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    icon: Icons.faBolt
                    title: qsTr("Streak:")
                    value: "7 Days"
                }

                StatBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    icon: Icons.faClock // Or similar
                    title: qsTr("Avg Accuracy:")
                    value: "92%"
                }

                StatBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    icon: Icons.faChartSimple
                    title: qsTr("Overall Accuracy")
                    value: "92%"
                }
            }

            // 4. Overall Progress
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 300

                CircularProgress {
                    anchors.centerIn: parent
                    height: parent.height * 0.8
                    width: height
                    lineWidth: 24
                    progress: 0.85
                    color: Theme.primary(Material.theme)
                    backgroundColor: Theme.surfaceContainerHighest(Material.theme)

                    // Text inside
                    Column {
                        anchors.centerIn: parent

                        Text {
                            text: qsTr("Overall Progress:")
                            font.pixelSize: 18
                            color: Theme.onSurfaceVariant(Material.theme)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
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
