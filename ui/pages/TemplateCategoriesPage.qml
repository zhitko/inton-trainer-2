import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import by.intontrainer.file 1.0
import by.intontrainer.statistics 1.0
import "../components"
import "../utils"

Page {
    id: categoriesPage
    title: qsTr("Reference samples")

    property string path: "data/patterns"
    property var allFolders: []

    Component.onCompleted: {
        allFolders = fileApi.getFolders(categoriesPage.path);
    }

    onVisibleChanged: {
        if (visible) {
            // Reload when page becomes visible
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

        // Categories (Folders) List — wrapped in RowLayout so scrollbar sits beside (not over) items
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

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
                    itemData: modelData
                    itemIndex: index
                    icon: Icons.faFolder
                    filePath: fileApi.getApplicationDirPath() + "/" + categoriesPage.path + "/" + modelData
                    isFolder: true
                    onClicked: {
                        console.log("Clicked category:", modelData);
                        stackView.push("TemplateFilesPage.qml", {
                            categoryPath: modelData,
                            categoryName: modelData
                        });
                    }
                }
            }

            // External scrollbar — sits beside the list, never overlapping it
            ScrollBar {
                id: vScrollBar
                Layout.fillHeight: true
                Layout.preferredWidth: 16
                orientation: Qt.Vertical
                policy: (window.settingsApi && !window.settingsApi.showNavigationMenu) ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                size: listView.visibleArea.heightRatio
                position: listView.visibleArea.yPosition
                onPositionChanged: {
                    if (pressed) listView.contentY = position * listView.contentHeight
                }
            }
        }
    }

    // Empty state
    EmptyState {
        anchors.centerIn: parent
        showEmpty: allFolders.length === 0 && !searchField.text
        emptyMessage: qsTr("No categories found")
    }
}
