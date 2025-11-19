import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import by.intontrainer.audio 1.0
import QtQuick.Controls.Material 6.8

import "../components"
import "../utils"


Page {
    property string filePath: ""

    title: filePath.substring(filePath.lastIndexOf('/') + 1)

    header: ToolBar {
        PlayButton {
            id: playButton
            width: 32
            height: 32
            file: filePath
        }
    }
}
