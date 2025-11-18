import QtQuick

Column {
    id: fileTreeView
    property var model
    property var name: ""
    property int indent: 0
    property string path: ""

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

        Text {
            id: title
            text: " "
            font.bold: false
            font.pointSize: 15
            leftPadding: 10
        }
    }

    Repeater {
        id: repeater

        delegate: Column {
            width: parent.width

            Loader {
                width: parent.width
                source: "FileTreeView.qml"
                // visible: fileTreeView.model[modelData] !== null

                onLoaded: {
                    item.path = (fileTreeView.path ? fileTreeView.path + "/" : "") + modelData;
                    item.indent = fileTreeView.indent + 1;
                    item.model = fileTreeView.model[modelData];
                    item.name = modelData;
                }
            }
        }
    }
}
