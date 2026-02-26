import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 6.8
import QtQuick.Window

import by.intontrainer.settings 1.0
import "utils"

ApplicationWindow {
    id: window
    // Window is sized to the scaled dimensions so it fits any screen.
    width: AppScale.designWidth * AppScale.factor
    height: AppScale.designHeight * AppScale.factor
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

    Component.onCompleted: {
        Logger.info("Main window initialized");
        Logger.debug("Initial theme: " + window.theme);
        Logger.debug("Screen: " + AppScale.screenWidth + "x" + AppScale.screenHeight + "  scaleFactor: " + AppScale.factor.toFixed(3));
    }

    Material.theme: window.theme
    Material.primary: Theme.primary(window.theme)
    Material.accent: Theme.accent(window.theme)
    Material.background: Theme.background(window.theme)

    // ── Scaled root ───────────────────────────────────────────────────────────
    // Always the original design size; the Scale transform zooms it to fit the
    // actual window. When factor == 1.0 the transform is a no-op.
    Item {
        id: scaledRoot
        width: AppScale.designWidth
        height: AppScale.designHeight
        transformOrigin: Item.TopLeft
        transform: Scale {
            xScale: AppScale.factor
            yScale: AppScale.factor
        }

        // ── Top toolbar ───────────────────────────────────────────────────────
        ToolBar {
            id: toolbar
            width: parent.width
            contentHeight: 56
            anchors.top: parent.top

            background: Rectangle {
                anchors.fill: parent
                color: Theme.surfaceContainer(Material.theme)
            }

            Button {
                id: menuButton
                font.family: Icons.familyRegular
                font.pointSize: menuButton.hovered ? 18 : 16
                text: Icons.faBars
                height: toolbar.height
                width: toolbar.height
                hoverEnabled: true
                onClicked: {
                    Logger.debug("Menu button clicked");
                    drawer.open();
                }

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

            Button {
                id: backButton
                anchors.right: parent.right
                font.family: Icons.familySolid
                font.pointSize: backButton.hovered ? 18 : 16
                text: Icons.faCircleLeft
                height: toolbar.height
                width: toolbar.height
                hoverEnabled: true
                onClicked: stackView.pop()
                visible: stackView.depth > 1

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
        }

        // ── Tab bar ───────────────────────────────────────────────────────────
        TabBar {
            id: tabBar
            width: parent.width
            anchors.bottom: parent.bottom

            TabButton {
                id: homeTabButton
                onClicked: {
                    stackView.clear();
                    stackView.push("pages/HomePage.qml");
                }
                font.family: Icons.familyRegular
                font.pointSize: 20
                text: Icons.faHome
            }
            TabButton {
                onClicked: stackView.push("pages/SettingsPage.qml")
                font.family: Icons.familySolid
                font.pointSize: 20
                font.bold: true
                text: Icons.faGear
            }
        }

        // ── Page content ──────────────────────────────────────────────────────
        StackView {
            id: stackView
            anchors {
                top: toolbar.bottom
                bottom: tabBar.top
                left: parent.left
                right: parent.right
            }

            initialItem: "pages/HomePage.qml"
        }

        // ── Side drawer ───────────────────────────────────────────────────────
        Drawer {
            id: drawer
            width: scaledRoot.width * 0.8
            height: scaledRoot.height
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
                        stackView.clear();
                        stackView.push("pages/HomePage.qml");
                        drawer.close();
                    }
                    contentItem: RowLayout {
                        spacing: 10
                        Text {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            font.family: Icons.familyRegular
                            text: Icons.faHome
                            color: Theme.onSurface(Material.theme)
                        }
                        Text {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: parent.parent.text
                            font: parent.parent.font
                            color: Theme.onSurface(Material.theme)
                        }
                    }
                }

                ItemDelegate {
                    text: qsTr("Patterns")
                    width: parent.width - parent.padding
                    onClicked: {
                        stackView.push("pages/TemplatesPage.qml");
                        drawer.close();
                    }
                    contentItem: RowLayout {
                        spacing: 10
                        Text {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            font.family: Icons.familySolid
                            font.bold: true
                            text: Icons.faFolderTree
                            color: Theme.onSurface(Material.theme)
                        }
                        Text {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: parent.parent.text
                            font: parent.parent.font
                            color: Theme.onSurface(Material.theme)
                        }
                    }
                }

                ItemDelegate {
                    text: qsTr("My Records")
                    width: parent.width - parent.padding
                    onClicked: {
                        stackView.push("pages/RecordsPage.qml");
                        drawer.close();
                    }
                    contentItem: RowLayout {
                        spacing: 10
                        Text {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            font.family: Icons.familySolid
                            font.bold: true
                            text: Icons.faBoxArchive
                            color: Theme.onSurface(Material.theme)
                        }
                        Text {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: parent.parent.text
                            font: parent.parent.font
                            color: Theme.onSurface(Material.theme)
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
                            color: Theme.onSurface(Material.theme)
                        }
                        Text {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: parent.parent.text
                            font: parent.parent.font
                            color: Theme.onSurface(Material.theme)
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
    }
}
