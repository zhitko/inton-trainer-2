pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8

import by.intontrainer.file 1.0
import by.intontrainer.statistics 1.0

import "../components"
import "../utils"

Page {
    id: recordsPage
    title: qsTr("Records")

    Material.theme: window.theme

    property string path: "data/records"
    property var allFiles: []
    
    // Wrapper object to help with QML model binding
    property var modelWrapper: {
        "items": []
    }

    // Get filtered items based on search
    function getFilteredItems() {
        if (!searchActionBar || !searchActionBar.searchText) {
            return recordsPage.allFiles;
        }
        var searchLower = searchActionBar.searchText.toLowerCase();
        return recordsPage.allFiles.filter(function(item) {
            return item.fileName.toLowerCase().includes(searchLower) ||
                   (item.patternName && item.patternName.toLowerCase().includes(searchLower));
        });
    }

    Component.onCompleted: {
        loadRecords();
    }

    onVisibleChanged: {
        if (visible) {
            loadRecords();
            listView.forceLayout();
        }
    }

    function loadRecords() {
        // Get all files from records folder
        var fileList = fileApi.getFilesList(recordsPage.path, ["*.wav"]);
        
        // Get history from statistics (microphone recordings)
        var historyList = statisticsApi.getAllHistory();
        
        // Create a map of userRecordPath -> history entry for quick lookup
        var historyMap = {};
        for (var i = 0; i < historyList.length; i++) {
            var entry = historyList[i];
            historyMap[entry.userRecordPath] = entry;
        }
        
        // Merge file list with history info
        recordsPage.allFiles = [];
        for (var j = 0; j < fileList.length; j++) {
            var file = fileList[j];
            var fullPath = recordsPage.path + "/" + file.filePath;
            
            // Check if this file has a history entry
            var historyEntry = historyMap[fullPath];
            
            if (historyEntry) {
                // This is a microphone recording with history
                // Get pattern name without "data/patterns/" prefix
                var fullPatternPath = historyEntry.patternPath;
                var patternDisplayName = fullPatternPath.replace("data/patterns/", "").replace(".wav", "");
                recordsPage.allFiles.push({
                    fileName: file.fileName,
                    filePath: file.filePath,
                    fullFilePath: fullPath,
                    directory: file.directory,
                    isHistory: true,
                    patternName: patternDisplayName,
                    refFilePath: historyEntry.patternPath,
                    result: historyEntry.result,
                    date: historyEntry.date
                });
            } else {
                // Regular file without history
                recordsPage.allFiles.push({
                    fileName: file.fileName,
                    filePath: file.filePath,
                    fullFilePath: fullPath,
                    directory: file.directory,
                    isHistory: false,
                    refFilePath: ""
                });
            }
        }
        
        // Update wrapper to trigger model change
        recordsPage.modelWrapper = {"items": recordsPage.getFilteredItems()};
        
        // Force ListView to update
        listView.forceLayout();
    }

    FileApi {
        id: fileApi
    }

    StatisticsApi {
        id: statisticsApi
    }

    ConfirmDialog {
        id: deleteAllDialog
        titleText: qsTr("Delete All Records")
        messageText: qsTr("Are you sure you want to delete all records?")
        confirmText: qsTr("Yes")
        cancelText: qsTr("No")
        isDestructive: true

        onAccepted: {
            for (let i = 0; i < recordsPage.allFiles.length; i++) {
                // Use the full path from the recordsPage.path + filePath
                let fullPath = recordsPage.path + "/" + recordsPage.allFiles[i].filePath;
                let absolutePath = fileApi.getApplicationDirPath() + "/" + fullPath;
                
                // Also remove history entry if exists
                if (recordsPage.allFiles[i].isHistory) {
                    statisticsApi.removeHistoryEntry(fullPath);
                }
                
                fileApi.deleteFile(absolutePath);
            }
            loadRecords();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // Action Bar (Search + Delete All)
        SearchActionBar {
            id: searchActionBar
            Layout.fillWidth: true
            actionButtonText: qsTr("Delete All")
            actionButtonVisible: recordsPage.modelWrapper.items.length > 0
            
            onSearchChanged: {
                // Update the filtered model when search text changes
                recordsPage.modelWrapper = {"items": recordsPage.getFilteredItems()};
            }
            
            onActionButtonClicked: {
                deleteAllDialog.open();
            }
        }

        // Records List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: recordsPage.modelWrapper.items

            section.property: "directory"
            section.criteria: ViewSection.FullString
            section.delegate: ListSectionHeader {
                sectionText: section
            }

            delegate: RecordItem {
                required property var modelData
                required property int index

                recordName: modelData.fileName
                itemIndex: index
                filePath: fileApi.getApplicationDirPath() + "/" + recordsPage.path + "/" + modelData.filePath
                
                // History properties
                isHistory: modelData.isHistory || false
                patternName: modelData.patternName || ""
                result: modelData.result || 0
                date: modelData.date || ""

                onClicked: {
                    var refPath = modelData.refFilePath ? fileApi.getApplicationDirPath() + "/" + modelData.refFilePath : "";
                    stackView.push("TemplatePage.qml", {
                        "userFilePath": filePath,
                        "refFilePath": refPath
                    });
                }

                onDeleted: {
                    // Remove history entry from statistics if exists - use full path
                    if (modelData.isHistory) {
                        var fullPathToDelete = recordsPage.path + "/" + modelData.filePath;
                        statisticsApi.removeHistoryEntry(fullPathToDelete);
                    }
                    loadRecords();
                }
            }
        }
    }

    // Empty state label
    EmptyState {
        showEmpty: recordsPage.modelWrapper.items.length === 0 && !searchActionBar.searchText
        emptyMessage: qsTr("No records found")
    }
}
