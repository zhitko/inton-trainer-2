import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.file 1.0
import "../components"
import "../utils"

Page {
    id: templatesPage
    title: qsTr("Patterns")

    property string path: "data/patterns"

    property var allFiles: []

    Component.onCompleted: {
        allFiles = fileApi.getFilesList(templatesPage.path, ["*.wav"]);
    }

    FileApi {
        id: fileApi
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // Search Bar
        SearchBar {
            id: searchField
        }

        // Patterns List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10

            model: {
                if (!searchField.text)
                    return allFiles;
                return allFiles.filter(file => file.fileName.toLowerCase().includes(searchField.text.toLowerCase()));
            }

            section.property: "directory"
            section.criteria: ViewSection.FullString
            section.delegate: Component {
                Item {
                    width: listView.width
                    height: 40

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: section
                        font.pixelSize: 16
                        font.weight: 700
                        color: Theme.onSurfaceVariant(templatesPage.Material.theme)
                        opacity: 0.7
                    }
                }
            }

            delegate: ListItem {
                itemData: modelData.fileName
                itemIndex: index
                icon: Icons.faFileAudio
                onClicked: {
                    console.log("Clicked template:", modelData.filePath);
                    stackView.push("TrainingPage.qml", {
                        referenceFilePath: fileApi.getApplicationDirPath() + "/" + templatesPage.path + "/" + modelData.filePath
                    });
                }
            }
        }
    }
}
