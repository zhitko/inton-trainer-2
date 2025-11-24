import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 6.8

ApplicationWindow {
    id: window
    width: 400
    height: 600
    visible: true
    title: qsTr("Inton Trainer")

    Material.theme: themeSwitch.checked ? Material.Dark : Material.Light

    header: ToolBar {
        contentHeight: 56

        Button {
            id: menuButton
            font.family: Icons.familyRegular
            font.pointSize: menuButton.hovered ? 18 : 16
            text: Icons.faBars
            height: window.header.height
            width: window.header.height
            hoverEnabled: true
            onClicked: drawer.open()

            background: Rectangle {
                color: "transparent"
            }

            transitions: Transition {
                NumberAnimation {
                    property: "font.pointSize"
                    duration: 100
                }
            }
        }

        Label {
            text: stackView.currentItem.title || qsTr("Inton Trainer")
            anchors.centerIn: parent
        }
    }

    Drawer {
        id: drawer
        width: window.width * 0.8
        height: window.height
        z: 1

        Column {
            anchors.fill: parent
            spacing: 10
            padding: 10

            RowLayout {

                RoundButton {
                    id: drawerCloseButton
                    font.family: Icons.familySolid
                    font.pixelSize: 24
                    font.bold: true
                    text: Icons.faAngleLeft
                    onClicked: drawer.close()
                    hoverEnabled: true
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height

                    background: Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: drawerCloseButton.hovered ? Material.rippleColor : "transparent"
                    }
                }
                Label {
                    text: "Menu"
                    font.pixelSize: 24
                    Layout.fillWidth: true
                }
            }
            ItemDelegate {
                id: homeItemDelegate
                text: "Home"
                width: parent.width - parent.padding
                onClicked: {
                    onClicked: stackView.push("pages/HomePage.qml")
                    drawer.close()
                }
                contentItem: RowLayout {
                    spacing: 10
                    Text {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        font.family: Icons.familyRegular
                        text: Icons.faHome
                        color: Material.primaryTextColor
                    }
                    Text {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.fillWidth: true
                        text: parent.parent.text
                        font: parent.parent.font
                        color: Material.primaryTextColor
                    }
                }
            }
            ItemDelegate {
                text: "Templates"
                width: parent.width - parent.padding
                onClicked: {
                    onClicked: stackView.push("pages/TemplatesPage.qml")
                    drawer.close()
                }
                contentItem: RowLayout {
                    spacing: 10
                    Text {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        font.family: Icons.familySolid
                        font.bold: true
                        text: Icons.faFolderTree
                        color: Material.primaryTextColor
                    }
                    Text {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.fillWidth: true
                        text: parent.parent.text
                        font: parent.parent.font
                        color: Material.primaryTextColor
                    }
                }
            }
            ItemDelegate {
                text: "My Records"
                width: parent.width - parent.padding
                onClicked: {
                    onClicked: stackView.push("pages/RecordsPage.qml")
                    drawer.close()
                }
                contentItem: RowLayout {
                    spacing: 10
                    Text {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        font.family: Icons.familySolid
                        font.bold: true
                        text: Icons.faBoxArchive
                        color: Material.primaryTextColor
                    }
                    Text {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.fillWidth: true
                        text: parent.parent.text
                        font: parent.parent.font
                        color: Material.primaryTextColor
                    }
                }
            }

            RowLayout {
                width: parent.width - parent.padding * 2
                Label {
                    text: "Dark Mode"
                }
                Switch {
                    id: themeSwitch
                    checked: false // Default to light mode
                }
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent

        initialItem: "pages/HomePage.qml"
    }

    footer: TabBar {
        id: tabBar

        TabButton {
            id: homeTabButton
            onClicked: stackView.push("pages/HomePage.qml")
            font.family: Icons.familyRegular
            font.pointSize: 20
            text: Icons.faHome
        }
        TabButton {
            onClicked: stackView.push("pages/RecordingPage.qml")
            font.family: Icons.familySolid
            font.pointSize: 20
            font.bold: true
            text: Icons.faMicrophone
        }
    }
}
