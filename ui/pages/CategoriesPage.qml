pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.file 1.0
import "../components"
import "../components/cards"
import "../utils"
import QtQuick.Effects

Page {
    id: root
    title: qsTr("Categories")

    property var allFolders: []

    Component.onCompleted: {
        allFolders = fileApi.getFolders("data/patterns");
    }

    FileApi {
        id: fileApi
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // Search Bar
        // Search Bar
        SearchBar {
            id: searchField
        }

        // Categories List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10

            model: {
                if (!searchField.text)
                    return allFolders;
                return allFolders.filter(folder => folder.toLowerCase().includes(searchField.text.toLowerCase()));
            }

            delegate: ListItem {
                required property string modelData
                required property int index
                itemData: modelData
                itemIndex: index
                onClicked: {
                    console.log("Clicked category:", modelData);
                    stackView.push("TemplatesPage.qml", {
                        path: "data/patterns/" + modelData
                    });
                }
            }
        }
    }
}
