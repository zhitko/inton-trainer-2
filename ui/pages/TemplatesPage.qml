import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.file 1.0
import by.intontrainer.statistics 1.0
import "../components"
import "../utils"

Page {
    id: templatesPage
    title: qsTr("Reference samples")

    property string path: "data/patterns"
    property var allFiles: []

    Component.onCompleted: {
        allFiles = fileApi.getFilesList(templatesPage.path, ["*.wav"]);
    }

    onVisibleChanged: {
        if (visible) {
            // Reload statistics when page becomes visible (e.g., when going back)
            // Trigger update of list items
            listView.forceLayout();
        }
    }

    FileApi {
        id: fileApi
    }

    StatisticsApi {
        id: statisticsApi
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

            ScrollBar.vertical: ScrollBar {
                policy: (window.settingsApi && !window.settingsApi.showNavigationMenu) ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }

            model: {
                if (!searchField.text)
                    return allFiles;
                return allFiles.filter(file => file.fileName.toLowerCase().includes(searchField.text.toLowerCase()));
            }

            section.property: "directory"
            section.criteria: ViewSection.FullString
            section.delegate: ListSectionHeader {
                sectionText: section
            }

            delegate: ListItem {
                itemData: modelData.fileName
                itemIndex: index
                icon: Icons.faFileAudio
                filePath: fileApi.getApplicationDirPath() + "/" + templatesPage.path + "/" + modelData.filePath
                isFolder: false
                onClicked: {
                    console.log("Clicked template:", modelData.filePath);
                    stackView.push("TrainingPage.qml", {
                        referenceFilePath: filePath
                    });
                }
            }
        }
    }

    // Empty state
    EmptyState {
        anchors.centerIn: parent
        showEmpty: allFiles.length === 0 && !searchField.text
        emptyMessage: qsTr("No templates found")
    }
}
