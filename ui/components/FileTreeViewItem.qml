import QtQuick
import QtQuick.Controls.Material

Column {
    id: fileItem
    property var model
    property var modelItem: ""
    property int indent: 0
    property string path: ""
    property bool canDelete: false
    signal fileClicked(string filePath)

    spacing: 6

    onModelChanged: {
        if (!!fileItem.model) {
            title.font.bold = true
            title.font.pointSize = 16
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
        deleteButton.file = fileItem.path
    }

    Row {
        spacing: 6
        DeleteButton {
            id: deleteButton
            height: title.height
            width: title.height
            visible: fileItem.canDelete
            onFileDeleted: {
                parent.visible = false
            }
        }
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
                font.pointSize: 15
            }
        }
    }

    FileTreeView {
        path: fileItem.path
        modelItem: fileItem.modelItem
        indent: fileItem.indent + 1
        model: fileItem.model
        canDelete: fileItem.canDelete
        onFileClicked: (filePath) => {
            fileItem.fileClicked(filePath)
        }
    }
}
