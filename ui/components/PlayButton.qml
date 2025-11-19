import QtQuick
import QtQuick.Controls
import by.intontrainer.audio 1.0

RoundButton {
    property string file: ""

    AudioApi {
        id: audioApi
    }

    width: 50
    height: width
    radius: width/2
    visible: file !== ""

    background: Image {
        source: audioApi.isPlaying ? "../../res/icons/stop.svg" : "../../res/icons/play.svg"
        anchors.fill: parent
        mipmap: true
    }

    onClicked: {
        if (audioApi.isPlaying) {
            audioApi.stopPlayback()
        } else {
            audioApi.play(file)
        }
    }
}
