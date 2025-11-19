import QtQuick
import QtQuick.Controls.Material

Column {
    id: fileTreeView
    property var model
    property var name: ""
    property int indent: 0
    property string path: ""
    signal fileClicked(string filePath)

    spacing: 5

    onModelChanged: {
        if (model) repeater.model = Object.keys(model)
        else repeater.model = []
    }

    onNameChanged: {
        title.text = name
        if (!!model) {
            title.font.bold = true
        } else {
            play.visible = true
        }
        row.leftPadding = indent * 20
    }
        
    Row {
        id: row
        leftPadding: 0
        PlayButton {
            id: play
            visible: false
            height: title.height
            width: title.height
            file: fileTreeView.path
        }

        Label {
            id: title
            text: " "
            font.bold: false
            font.pointSize: 15
            leftPadding: 10
            rightPadding: 10
            color: Material.primaryTextColor
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("FileTreeView.title.onClicked:", fileTreeView.name)
                    if (!fileTreeView.model) {
                        console.log("FileTreeView.title.onClicked: fileClicked()", fileTreeView.name)
                        fileTreeView.fileClicked(fileTreeView.path)
                    }
                }
            }
        }
    }

    Repeater {
        id: repeater

        delegate: Column {
            width: parent.width

            Loader {
                width: parent.width
                source: "FileTreeView.qml"

                onLoaded: {
                    item.path = (fileTreeView.path ? fileTreeView.path + "/" : "") + modelData;
                    item.indent = fileTreeView.indent + 1;
                    item.model = fileTreeView.model[modelData];
                    item.name = modelData;
                    item.name = modelData;
                }
            }
        }
    }
}
