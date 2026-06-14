import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import "../utils"

RowLayout {
    property alias searchText: searchField.text
    property string actionButtonText: ""
    property bool actionButtonVisible: true
    property bool actionButtonEnabled: true
    
    signal actionButtonClicked
    signal searchChanged(string text)

    SearchBar {
        id: searchField
        Layout.fillWidth: true
        onTextChanged: {
            searchChanged(text);
        }
    }

    Button {
        id: actionButton
        visible: actionButtonVisible
        enabled: actionButtonEnabled
        Layout.alignment: Qt.AlignVCenter

        contentItem: RowLayout {
            spacing: 8
            Text {
                text: Icons.faTrash
                font.family: Icons.familySolid
                font.bold: true
                font.pixelSize: AppScale.fs(16)
                color: Theme.onError(Material.theme)
            }
            Text {
                text: actionButtonText
                font.pixelSize: AppScale.fs(14)
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
                opacity: actionButton.hovered ? 0.08 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        onClicked: {
            actionButtonClicked();
        }
    }
}
