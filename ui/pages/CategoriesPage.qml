pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.file 1.0
import by.intontrainer.statistics 1.0
import "../components"
import "../components/cards"
import "../utils"
import QtQuick.Effects

Page {
    id: root
    title: qsTr("Reference samples")

    property string path: "data/patterns"
    property var allFolders: []

    FileApi {
        id: fileApi
    }

    StatisticsApi {
        id: statisticsApi
    }

    Component.onCompleted: {
        allFolders = fileApi.getFolders(root.path);
    }

    onVisibleChanged: {
        if (visible) {
            // Trigger update of list items
            listView.forceLayout();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

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
                filePath: root.path + "/" + modelData
                isFolder: true
                onClicked: {
                    console.log("Clicked category:", modelData);
                    let folderPath = root.path + "/" + modelData;
                    let subFolders = fileApi.getFolders(folderPath);
                    if (subFolders.length > 0) {
                        stackView.push("CategoriesPage.qml", {
                            path: folderPath
                        });
                    } else {
                        stackView.push("TemplatesPage.qml", {
                            path: folderPath
                        });
                    }
                }
            }
        }
    }
}
