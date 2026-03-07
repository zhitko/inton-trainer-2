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

    Binding {
        target: Theme
        property: "primaryColorName"
        value: settingsApi.primaryColor
    }

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
    Item {
        id: scaledRoot
        width: window.width / AppScale.factor
        height: window.height / AppScale.factor
        transformOrigin: Item.TopLeft
        transform: Scale {
            xScale: AppScale.factor
            yScale: AppScale.factor
        }

        // ── Top toolbar ───────────────────────────────────────────────────────
        ToolBar {
            id: toolbar
            width: parent.width
            contentHeight: 64
            anchors.top: parent.top

            background: Rectangle {
                anchors.fill: parent
                color: Theme.surface(Material.theme)
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant(Material.theme)
                    opacity: 0.5
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                ToolButton {
                    id: menuButton
                    font.family: Icons.familyRegular
                    text: Icons.faBars
                    font.pixelSize: 20
                    onClicked: drawer.open()

                    background: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: 24
                        color: menuButton.hovered ? Theme.surfaceContainerLow(Material.theme) : "transparent"
                    }
                }

                Label {
                    text: stackView.currentItem.title || qsTr("Inton Trainer")
                    font.pixelSize: 22
                    font.weight: Font.Normal
                    Layout.fillWidth: true
                    elide: Label.ElideRight
                    color: Theme.onSurface(Material.theme)
                    leftPadding: 8
                }

                ToolButton {
                    id: backButton
                    font.family: Icons.familySolid
                    text: Icons.faArrowLeft
                    font.pixelSize: 20
                    onClicked: stackView.pop()
                    visible: stackView.depth > 1

                    background: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: 24
                        color: backButton.hovered ? Theme.surfaceContainerLow(Material.theme) : "transparent"
                    }
                }
            }
        }

        // ── Navigation Bar ─────────────────────────────
        Rectangle {
            id: navigationBar
            width: parent.width
            height: 80
            anchors.bottom: parent.bottom
            color: Theme.surfaceContainer(Material.theme)

            Row {
                anchors.fill: parent

                // Home Tab
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: 64
                            height: 32
                            radius: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: stackView.depth <= 1 ? Theme.secondaryContainer(Material.theme) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                font.family: Icons.familySolid
                                font.pixelSize: 20
                                text: Icons.faHome
                                color: stackView.depth <= 1 ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurfaceVariant(Material.theme)
                            }
                        }

                        Text {
                            text: qsTr("Home")
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: 12
                            font.weight: stackView.depth <= 1 ? Font.Bold : Font.Normal
                            color: stackView.depth <= 1 ? Theme.onSurface(Material.theme) : Theme.onSurfaceVariant(Material.theme)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            stackView.clear();
                            stackView.push("pages/HomePage.qml");
                        }
                    }
                }

                // Settings Tab
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: 64
                            height: 32
                            radius: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: stackView.currentItem && stackView.currentItem.title === qsTr("Settings") ? Theme.secondaryContainer(Material.theme) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                font.family: Icons.familySolid
                                font.pixelSize: 20
                                text: Icons.faGear
                                color: stackView.currentItem && stackView.currentItem.title === qsTr("Settings") ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurfaceVariant(Material.theme)
                            }
                        }

                        Text {
                            text: qsTr("Settings")
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: 12
                            font.weight: stackView.currentItem && stackView.currentItem.title === qsTr("Settings") ? Font.Bold : Font.Normal
                            color: stackView.currentItem && stackView.currentItem.title === qsTr("Settings") ? Theme.onSurface(Material.theme) : Theme.onSurfaceVariant(Material.theme)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (stackView.currentItem.title !== qsTr("Settings")) {
                                stackView.push("pages/SettingsPage.qml");
                            }
                        }
                    }
                }
            }
        }

        // ── Page content ──────────────────────────────────────────────────────
        StackView {
            id: stackView
            anchors {
                top: toolbar.bottom
                bottom: navigationBar.top
                left: parent.left
                right: parent.right
            }

            initialItem: "pages/HomePage.qml"
        }

        // ── Side drawer ───────────────────────────────────────────────────────
        Drawer {
            id: drawer
            width: Math.min(scaledRoot.width * 0.8, 360)
            height: scaledRoot.height
            z: 2

            background: Rectangle {
                color: Theme.surface(Material.theme)
                radius: 16
                layer.enabled: true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 0

                Label {
                    text: qsTr("Inton Trainer")
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Theme.onSurfaceVariant(Material.theme)
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                    Layout.bottomMargin: 16
                }

                Repeater {
                    model: [
                        {
                            text: qsTr("Home"),
                            icon: Icons.faHome,
                            page: "pages/HomePage.qml",
                            clear: true
                        },
                        {
                            text: qsTr("Patterns"),
                            icon: Icons.faFolderTree,
                            page: "pages/TemplatesPage.qml",
                            clear: false
                        },
                        {
                            text: qsTr("My Records"),
                            icon: Icons.faBoxArchive,
                            page: "pages/RecordsPage.qml",
                            clear: false
                        },
                        {
                            text: qsTr("Settings"),
                            icon: Icons.faGear,
                            page: "pages/SettingsPage.qml",
                            clear: false
                        }
                    ]

                    delegate: ItemDelegate {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56

                        contentItem: RowLayout {
                            spacing: 12
                            Text {
                                font.family: Icons.familySolid
                                text: modelData.icon
                                font.pixelSize: 18
                                font.bold: true
                                color: parent.parent.highlighted ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurfaceVariant(Material.theme)
                                Layout.leftMargin: 4
                            }
                            Label {
                                text: modelData.text
                                font.pixelSize: 14
                                font.weight: parent.parent.highlighted ? Font.Bold : Font.Normal
                                color: parent.parent.highlighted ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
                                Layout.fillWidth: true
                            }
                        }

                        highlighted: {
                            if (modelData.text === qsTr("Home"))
                                return stackView.depth <= 1;
                            return stackView.currentItem && stackView.currentItem.title === modelData.text;
                        }

                        background: Rectangle {
                            radius: 28
                            color: parent.highlighted ? Theme.secondaryContainer(Material.theme) : (parent.hovered ? Theme.surfaceContainerLow(Material.theme) : "transparent")
                        }

                        onClicked: {
                            if (modelData.clear) {
                                stackView.clear();
                            }
                            stackView.push(modelData.page);
                            drawer.close();
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                } // Spacer

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.outlineVariant(Material.theme)
                    Layout.bottomMargin: 8
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 16
                    Label {
                        text: qsTr("Dark Mode")
                        Layout.fillWidth: true
                        color: Theme.onSurface(Material.theme)
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
