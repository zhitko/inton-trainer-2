import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.file 1.0
import by.intontrainer.statistics 1.0
import "../components"
import "../utils"

Page {
    id: filesPage
    title: categoryName

    property string categoryPath: ""
    property string categoryName: ""
    property var allFiles: []
    property string currentFilter: "all" // all, noScore, above80, below80

    Component.onCompleted: {
        loadFiles();
    }

    onVisibleChanged: {
        if (visible) {
            // Reload statistics when page becomes visible
            loadFiles();
            listView.forceLayout();
        }
    }

    function loadFiles() {
        // Load all files from the category and subdirectories
        let basePath = "data/patterns/" + categoryPath;
        let files = fileApi.getFilesList(basePath, ["*.wav"]);
        
        // Convert to array and enrich with statistics
        allFiles = files.map(function(file) {
            let filePath = basePath + "/" + file.filePath;
            let score = statisticsApi.getBestResultForFile(filePath);
            let filePathStr = String(file.filePath);
            let lastSlash = filePathStr.lastIndexOf('/');
            let dir = lastSlash > 0 ? filePathStr.substring(0, lastSlash) : qsTr("Root");
            return {
                fileName: file.fileName,
                filePath: filePath,
                fullPath: fileApi.getApplicationDirPath() + "/" + filePath,
                score: score,
                hasScore: score > 0,
                directory: dir
            };
        });
        
        // Sort by directory and then by natural file name order
        allFiles.sort((a, b) => {
            let dirCompare = a.directory.localeCompare(b.directory);
            if (dirCompare !== 0)
                return dirCompare;
            return a.fileName.localeCompare(b.fileName);
        });
    }

    function applyFilter(files) {
        return files.filter(function(file) {
            switch (currentFilter) {
                case "noScore":
                    return !file.hasScore;
                case "above80":
                    return file.hasScore && file.score >= 80;
                case "below80":
                    return file.hasScore && file.score < 80;
                default:
                    return true;
            }
        });
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
        spacing: 16

        // Search Bar
        SearchBar {
            id: searchField
        }

        // Filter Chips
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: filterLayout.implicitHeight + 16
            radius: Theme.shapeSmall
            color: Theme.surfaceContainerLow(Material.theme)

            ColumnLayout {
                id: filterLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Flow {
                    spacing: 8
                    flow: Flow.LeftToRight
                    Layout.fillWidth: true

                    Chip {
                        text: qsTr("All files")
                        icon: Icons.faList
                        selected: currentFilter === "all"
                        onClicked: {
                            currentFilter = "all";
                        }
                    }

                    Chip {
                        text: qsTr("New")
                        icon: Icons.faClock
                        selected: currentFilter === "noScore"
                        onClicked: {
                            currentFilter = "noScore";
                        }
                    }

                    Chip {
                        text: qsTr("Improve")
                        icon: Icons.faArrowTrendUp
                        selected: currentFilter === "below80"
                        onClicked: {
                            currentFilter = "below80";
                        }
                    }

                    Chip {
                        text: qsTr("Mastered")
                        icon: Icons.faTrophy
                        selected: currentFilter === "above80"
                        onClicked: {
                            currentFilter = "above80";
                        }
                    }
                }
            }
        }

        // Files List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10

            model: {
                let filtered = applyFilter(allFiles);
                if (!searchField.text)
                    return filtered;
                return filtered.filter(file => file.fileName.toLowerCase().includes(searchField.text.toLowerCase()));
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
                filePath: modelData.fullPath
                isFolder: false
                onClicked: {
                    console.log("Clicked file:", modelData.filePath);
                    stackView.push("TrainingPage.qml", {
                        referenceFilePath: modelData.fullPath
                    });
                }
            }
        }
    }

    // Empty state
    EmptyState {
        anchors.centerIn: parent
        showEmpty: applyFilter(allFiles).filter(file => !searchField.text || file.fileName.toLowerCase().includes(searchField.text.toLowerCase())).length === 0
        emptyMessage: {
            if (allFiles.length === 0) {
                return qsTr("No files found");
            } else if (searchField.text) {
                return qsTr("No files match your search");
            } else {
                return qsTr("No files match the current filter");
            }
        }
    }
}
