import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import "../components"
import "../components/cards"
import "../utils"

Page {
    id: root
    title: qsTr("Home")

    readonly property var settingsApi: ApplicationWindow.window ? ApplicationWindow.window.settingsApi : null

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
                Layout.bottomMargin: 20
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
                Layout.topMargin: 20
                spacing: 12

                StatBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    icon: Icons.faBolt
                    title: qsTr("Streak:")
                    value: "7" + qsTr(" Days")
                }

                StatBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    icon: Icons.faClock
                    title: qsTr("Avg Accuracy:")
                    value: "92%"
                }

                StatBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    icon: Icons.faChartSimple
                    title: qsTr("Overall")
                    value: "92%"
                }
            }

            // 4. Overall Progress
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 180

                CircularProgress {
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
                            text: qsTr("Overall Progress")
                            font.pixelSize: 14
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
