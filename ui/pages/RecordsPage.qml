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
                var patternFileName = fullPatternPath.substring(fullPatternPath.lastIndexOf('/') + 1).replace(".wav", "");
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
        recordsPage.modelWrapper = {"items": recordsPage.allFiles};
        
        // Force ListView to update
        listView.forceLayout();
    }

    FileApi {
        id: fileApi
    }

    StatisticsApi {
        id: statisticsApi
    }

    Dialog {
        id: deleteAllDialog
        anchors.centerIn: parent
        modal: true
        title: qsTr("Delete All Records")

        header: Label {
            text: deleteAllDialog.title
            font.pixelSize: 20
            font.bold: true
            padding: 24
            bottomPadding: 0
            color: Theme.onSurface(Material.theme)
        }

        contentItem: Text {
            text: qsTr("Are you sure you want to delete all records?")
            color: Theme.onSurfaceVariant(Material.theme)
            font.pixelSize: 16
            padding: 24
        }

        footer: DialogButtonBox {
            Button {
                text: qsTr("Yes")
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                Material.foreground: Theme.error(Material.theme)
            }
            Button {
                text: qsTr("No")
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                Material.foreground: Theme.primary(Material.theme)
            }
        }

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
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            SearchBar {
                id: searchField
                Layout.fillWidth: true
            }

            Button {
                id: deleteAllButton
                visible: recordsPage.modelWrapper.items.length > 0
                Layout.alignment: Qt.AlignVCenter

                contentItem: RowLayout {
                    spacing: 8
                    Text {
                        text: Icons.faTrash
                        font.family: Icons.familySolid
                        font.bold: true
                        font.pixelSize: 16
                        color: Theme.onError(Material.theme)
                    }
                    Text {
                        text: qsTr("Delete All")
                        font.pixelSize: 14
                        font.weight: 600
                        color: Theme.onError(Material.theme)
                    }
                }

                background: Rectangle {
                    radius: 20
                    color: Theme.error(Material.theme)
                    implicitHeight: 40
                    implicitWidth: 120

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.onError(Material.theme)
                        opacity: deleteAllButton.hovered ? 0.08 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                onClicked: {
                    deleteAllDialog.open();
                }
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

            // Section is disabled for now - can be added back later
            // section.property: "directory"
            // section.criteria: ViewSection.FullString
            section.delegate: Component {
                Item {
                    width: listView.width
                    height: 40
                    visible: section !== ""

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: section
                        font.pixelSize: 16
                        font.weight: 700
                        color: Theme.onSurfaceVariant(Material.theme)
                        opacity: 0.7
                    }
                }
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
    Text {
        visible: recordsPage.modelWrapper.items.length === 0 && !searchField.text
        text: qsTr("No records found")
        font.pixelSize: 18
        color: Theme.onSurfaceVariant(Material.theme)
        anchors.centerIn: parent
        opacity: 0.7
    }
}
