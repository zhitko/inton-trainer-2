import QtQuick
import QtQuick.Controls.Material

Column {
    id: fileItem
    property var model
    property var modelItem: ""
    property int indent: 0
    property string path: ""
    signal fileClicked(string filePath)

    spacing: 6

    onModelChanged: {
        if (!!fileItem.model) {
            title.font.bold = true
            playButton.visible = false
        }
    }

    onModelItemChanged: {
        title.text = fileItem.modelItem
    }

    onIndentChanged: {
        fileItem.leftPadding = fileItem.indent * 10
    }

    onPathChanged: {
        playButton.file = fileItem.path
    }

    Row {
        spacing: 6
        PlayButton {
            id: playButton
            height: title.height
            width: title.height
        }
        Label {
            id: title
            font.pointSize: 14
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!fileItem.model) {
                        console.log("ui/components/FileTreeViewItem.qml:onClicked", fileItem.path)
                        fileItem.fileClicked(fileItem.path)
                    }
                }
            }
        }
    }

    FileTreeView {
        path: fileItem.path
        modelItem: fileItem.modelItem
        indent: fileItem.indent + 1
        model: fileItem.model
        onFileClicked: (filePath) => {
            fileItem.fileClicked(filePath)
        }
    }
}
