import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.audio 1.0
import "../utils"

ColumnLayout {
    id: root
    spacing: 8

    property string filePath: ""
    readonly property bool isRecording: audioApi.isRecording
    readonly property real audioLevel: audioApi.audioLevel
    signal clicked

    AudioApi {
        id: audioApi
    }

    Item {
        id: buttonContainer
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 84
        Layout.preferredHeight: 84

        Rectangle {
            id: outerCircle
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: Theme.error(Material.theme)
            border.width: 2

            Behavior on border.color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        Rectangle {
            id: innerCircle
            anchors.centerIn: parent
            width: root.isRecording ? 64 : 72
            height: width
            radius: width / 2
            color: Theme.error(Material.theme)

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.isRecording ? Icons.faStop : Icons.faMicrophone
                font.family: Icons.familySolid
                font.pixelSize: 28
                font.bold: true
                color: Theme.onError(Material.theme)
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (audioApi.isRecording) {
                        audioApi.stopRecording();
                    } else if (root.filePath !== "") {
                        audioApi.startRecording(root.filePath);
                    }
                    root.clicked();
                }
            }
        }

        // Pulse Animation for recording
        Rectangle {
            id: pulse
            anchors.centerIn: parent
            width: innerCircle.width
            height: innerCircle.height
            radius: width / 2
            color: Theme.error(Material.theme)
            opacity: 0
            z: -1
            scale: 1.0

            SequentialAnimation {
                running: root.isRecording
                loops: Animation.Infinite

                ParallelAnimation {
                    NumberAnimation {
                        target: pulse
                        property: "scale"
                        from: 1.0
                        to: 1.6
                        duration: 1200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: pulse
                        property: "opacity"
                        from: 0.6
                        to: 0
                        duration: 1200
                        easing.type: Easing.OutCubic
                    }
                }
                PropertyAction {
                    target: pulse
                    property: "scale"
                    value: 1.0
                }
                PropertyAction {
                    target: pulse
                    property: "opacity"
                    value: 0
                }
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Record")
        font.pixelSize: 14
        font.weight: 600
        color: Theme.onSurface(Material.theme)
    }
}
