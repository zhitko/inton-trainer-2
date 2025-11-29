import QtQuick
import QtQuick.Controls
import by.intontrainer.audio 1.0
import QtQuick.Controls.Material 6.8

RoundButton {
    id: control
    property string file: ""
    property bool showLabel: false

    AudioApi {
        id: audioApi
    }

    width: 50
    height: width
    radius: width / 2
    visible: file !== ""

    background: Rectangle {
        radius: control.radius
        anchors.fill: parent
        Label {
            id: label
            font.family: Icons.familySolid
            font.bold: true
            text: audioApi.isPlaying ? (Icons.faStop + " " + (control.showLabel ? qsTr("Stop") : "")) : (Icons.faPlay + " " + (control.showLabel ? qsTr("Play") : ""))
            Material.foreground: audioApi.isPlaying ? Material.DeepOrange : Material.primaryTextColor
            anchors.left: parent.left
            anchors.leftMargin: parent.width / 3
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            font.pixelSize: parent.width / 2
            verticalAlignment: Label.AlignVCenter
        }
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                parent.color = Material.rippleColor;
                label.font.pixelSize += 4;
            }
            onExited: {
                parent.color = Material.backgroundColor;
                label.font.pixelSize -= 4;
            }
        }
    }

    onClicked: {
        if (audioApi.isPlaying) {
            audioApi.stopPlayback();
        } else {
            audioApi.play(file);
        }
    }
}
