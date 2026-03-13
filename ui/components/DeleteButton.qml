import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 6.8

import by.intontrainer.file 1.0

RoundButton {
    id: control
    property string file: ""

    width: 50
    height: width
    radius: width / 2
    visible: file !== ""

    signal fileDeleted(string filePath)

    FileApi {
        id: fileApi
    }

    background: Rectangle {
        radius: control.radius
        anchors.fill: parent
        color: control.hovered ? Theme.surfaceContainerLow(Material.theme) : "transparent"
        Label {
            id: label
            anchors.centerIn: parent
            font.family: Icons.familySolid
            font.bold: true
            text: Icons.faTrash
            font.pixelSize: (parent.width / 2) + (control.hovered ? 4 : 0)
            color: Theme.onSurface(Material.theme)
            horizontalAlignment: Label.AlignHCenter
            Behavior on font.pixelSize {
                NumberAnimation { duration: 100 }
            }
        }
    }

    onClicked: {
        fileApi.deleteFile(control.file);
        control.fileDeleted(control.file);
    }
}
