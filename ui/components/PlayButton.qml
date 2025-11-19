import QtQuick
import QtQuick.Controls
import by.intontrainer.audio 1.0
import QtQuick.Controls.Material 6.8

RoundButton {
    property string file: ""

    AudioApi {
        id: audioApi
    }

    width: 50
    height: width
    radius: width/2
    visible: file !== ""

    background: Label {
        font.family: Icons.familySolid
        font.bold: true
        text: audioApi.isPlaying ? Icons.faStop : Icons.faPlay
        Material.foreground: audioApi.isPlaying ? Material.DeepOrange : Material.primaryTextColor
        anchors.centerIn: parent
        font.pixelSize: parent.width / 2
        horizontalAlignment: Label.AlignHCenter
    }

    onClicked: {
        if (audioApi.isPlaying) {
            audioApi.stopPlayback()
        } else {
            audioApi.play(file)
        }
    }
}
