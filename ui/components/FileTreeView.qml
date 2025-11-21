import QtQuick
import QtQuick.Controls.Material

Column {
    id: fileView
    property var model
    property var modelItem: ""
    property int indent: 0
    property string path: ""
    property bool canDelete: false
    signal fileClicked(string filePath)

    spacing: 5

    Repeater {
        id: repeater
        model: !!fileView.model ? Object.keys(fileView.model) : {}
        Loader {
            source: "FileTreeViewItem.qml"

            onLoaded: {
                item.path = (fileView.path ? fileView.path + "/" : "") + modelData;
                item.modelItem = modelData
                item.indent = indent
                item.model = fileView.model[modelData]
                item.canDelete = fileView.canDelete
                item.fileClicked.connect((filePath) => {
                    console.log("ui/components/FileTreeView.qml:fileClicked", filePath)
                    fileView.fileClicked(filePath)
                })
            }
        }
    }
}
