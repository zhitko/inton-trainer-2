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
    property string icon: Icons.faPlay
    property string text: ""
    readonly property bool isPlaying: audioApi.isPlaying
    property alias enabled: button.enabled
    enabled: filePath !== ""
    signal clicked

    AudioApi {
        id: audioApi
    }

    RoundButton {
        id: button
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 56
        Layout.preferredHeight: 56
        font.family: Icons.familySolid
        font.weight: Icons.fontSolid.weight
        text: root.isPlaying ? Icons.faStop : root.icon
        font.pixelSize: 20
        Material.background: root.isPlaying ? Theme.errorContainer(Material.theme) : Theme.primaryContainer(Material.theme)
        Material.foreground: root.isPlaying ? Theme.onErrorContainer(Material.theme) : Theme.onPrimaryContainer(Material.theme)

        hoverEnabled: true

        // MD3 State Layer overlay for hover state (8% opacity)
        background: Rectangle {
            radius: button.radius
            color: button.Material.backgroundColor

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: button.Material.foreground
                opacity: button.hovered && !root.isPlaying ? 0.08 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        onClicked: {
            if (audioApi.isPlaying) {
                audioApi.stopPlayback();
            } else if (root.filePath !== "") {
                audioApi.play(root.filePath);
            }
            root.clicked();
        }

        // Pulse Animation
        Rectangle {
            id: pulse
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: width / 2
            color: button.Material.background
            opacity: 0
            z: -1
            scale: 1.0

            SequentialAnimation {
                id: pulseAnimation
                running: root.isPlaying
                loops: Animation.Infinite

                onRunningChanged: {
                    if (!running) {
                        pulse.scale = 1.0;
                        pulse.opacity = 0;
                    }
                }

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
        text: root.text
        font.pixelSize: 12
        font.weight: 500
        horizontalAlignment: Text.AlignHCenter
        color: Theme.onSurface(Material.theme)
    }
}
