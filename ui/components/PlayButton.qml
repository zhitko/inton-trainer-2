import QtQuick
import QtQuick.Controls
import by.intontrainer.audio 1.0

RoundButton {
    property string file: ""

    AudioAPI {
        id: audioAPI
    }

    width: 50
    height: width
    radius: width/2
    visible: file !== ""

    background: Image {
        source: audioAPI.isPlaying ? "../../res/icons/stop.svg" : "../../res/icons/play.svg"
        anchors.fill: parent
        mipmap: true
    }

    onClicked: {
        if (audioAPI.isPlaying) {
            audioAPI.stopPlayback()
        } else {
            audioAPI.play(file)
        }
    }
}
