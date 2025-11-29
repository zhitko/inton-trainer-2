import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 6.8

import by.intontrainer.settings 1.0

ApplicationWindow {
    id: window
    width: 400
    height: 600
    visible: true
    title: qsTr("Inton Trainer")

    SettingsApi {
        id: settingsApi
        onThemeChanged: {
            window.theme = getTheme();
        }
    }

    property alias settingsApi: settingsApi

    function getTheme() {
        return settingsApi.theme === "dark" ? Material.Dark : (settingsApi.theme === "light" ? Material.Light : Material.System);
    }

    property var theme: getTheme()

    Material.theme: window.theme

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
                    text: qsTr("Menu")
                    font.pixelSize: 24
                    Layout.fillWidth: true
                }
            }
            ItemDelegate {
                id: homeItemDelegate
                text: qsTr("Home")
                width: parent.width - parent.padding
                onClicked: {
                    onClicked: stackView.push("pages/HomePage.qml");
                    drawer.close();
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
                text: qsTr("Templates")
                width: parent.width - parent.padding
                onClicked: {
                    onClicked: stackView.push("pages/TemplatesPage.qml");
                    drawer.close();
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
                text: qsTr("My Records")
                width: parent.width - parent.padding
                onClicked: {
                    onClicked: stackView.push("pages/RecordsPage.qml");
                    drawer.close();
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
            ItemDelegate {
                text: qsTr("Settings")
                width: parent.width - parent.padding
                onClicked: {
                    stackView.push("pages/SettingsPage.qml");
                    drawer.close();
                }
                contentItem: RowLayout {
                    spacing: 10
                    Text {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        font.family: Icons.familySolid
                        font.bold: true
                        text: Icons.faGear
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
                    text: qsTr("Dark Mode")
                }
                Switch {
                    checked: window.theme === Material.Dark
                    onCheckedChanged: {
                        settingsApi.theme = checked ? "dark" : "light";
                        settingsApi.save();
                    }
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
