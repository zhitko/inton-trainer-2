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
            mouseArea.hoverEnabled = false
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
        Rectangle {
            color: Material.backgroundColor
            height: title.height
            width: title.width
            MouseArea {
                id: mouseArea
                hoverEnabled: true
                anchors.fill: parent
                onClicked: {
                    if (!fileItem.model) {
                        console.log("ui/components/FileTreeViewItem.qml:onClicked", fileItem.path)
                        fileItem.fileClicked(fileItem.path)
                    }
                }
                onEntered: {
                    parent.color = Material.rippleColor
                }
                onExited: {
                    parent.color = Material.backgroundColor
                }
            }
            Text {
                id: title
                font.pointSize: 14            
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
