pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import "../utils"

Item {
    id: root

    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true
    Layout.preferredHeight: 200

    property alias text: label.text
    signal clicked

    property var waveHeights: [64, 44, 28, 20, 32, 20, 40, 24, 20, 4, 10, 4]

    Row {
        anchors.centerIn: parent
        spacing: 8

        // Left Waveform
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            layoutDirection: Qt.RightToLeft // Grow outwards from button

            Repeater {
                model: root.waveHeights
                Rectangle {
                    id: leftWaveBar
                    required property int index
                    required property int modelData
                    width: 4
                    height: leftWaveBar.modelData
                    radius: 2
                    color: Theme.secondary(Material.theme)
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.8 - (leftWaveBar.index * 0.05) // Fade slighty

                    SequentialAnimation on height {
                        running: startButtonMouseArea.containsMouse
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: leftWaveBar.modelData * 1.3
                            duration: 600 + (leftWaveBar.index * 40)
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: leftWaveBar.modelData
                            duration: 600 + (leftWaveBar.index * 40)
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }

        // Main Circle Button
        Item {
            width: 200
            height: 200

            // MD3 Elevation shadow effect (replaces glow)
            Rectangle {
                id: buttonGlow
                anchors.centerIn: parent
                width: 200
                height: 200
                radius: 100
                color: "transparent"
                opacity: 0
                
                // MD3 Elevation 3 shadow for prominent button
                layer.enabled: startButtonMouseArea.containsMouse
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.3)
                    blur: 0.8
                    shadowVerticalOffset: 8
                    shadowHorizontalOffset: 0
                }
            }

            Rectangle {
                id: mainButtonBg
                anchors.fill: parent
                radius: width / 2
                scale: startButtonMouseArea.pressed ? 0.95 : (startButtonMouseArea.containsMouse ? 1.05 : 1.0)

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Theme.primary(Material.theme)
                    }
                    GradientStop {
                        position: 1.0
                        color: Theme.primary(Material.theme)
                    }
                }

                MouseArea {
                    id: startButtonMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.clicked()
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: [4, 8, 12, 20, 32, 52, 84, 52, 32, 20, 12, 8, 4]
                        Rectangle {
                            id: innerBar
                            required property int index
                            required property int modelData
                            width: 4
                            height: innerBar.modelData
                            radius: 2
                            color: Theme.onPrimary(Material.theme)
                            opacity: 0.2
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on height {
                                running: startButtonMouseArea.containsMouse
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: innerBar.modelData * 1.5
                                    duration: 500 + (innerBar.index * 50)
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: innerBar.modelData
                                    duration: 500 + (innerBar.index * 50)
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }

                Label {
                    id: label
                    anchors.centerIn: parent
                    text: qsTr("Start Training")
                    color: Theme.onPrimary(Material.theme)
                    font.bold: true
                    font.pixelSize: AppScale.fs(18)
                }
            }
        }

        // Right Waveform
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: root.waveHeights
                Rectangle {
                    id: rightWaveBar
                    required property int index
                    required property int modelData
                    width: 4
                    height: rightWaveBar.modelData
                    radius: 2
                    color: Theme.secondary(Material.theme)
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.8 - (rightWaveBar.index * 0.05)

                    SequentialAnimation on height {
                        running: startButtonMouseArea.containsMouse
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: rightWaveBar.modelData * 1.3
                            duration: 600 + (rightWaveBar.index * 40)
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: rightWaveBar.modelData
                            duration: 600 + (rightWaveBar.index * 40)
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }
    }
}
