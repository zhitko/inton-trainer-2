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

    readonly property bool trainingPageActive: stackView.currentItem && stackView.currentItem.isTrainingPage === true
    property bool trainingRecordingStartedOnce: false

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
                    font.weight: Icons.fontRegular.weight
                    text: Icons.faBars
                    font.pixelSize: 20
                    onClicked: drawer.open()

                    background: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: Theme.shapeMedium // MD3 medium shape token
                        color: menuButton.hovered ? Theme.surfaceContainerLow(Material.theme) : "transparent"

                        // MD3 State Layer - hover effect (8% opacity)
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.onSurface(Material.theme)
                            opacity: menuButton.hovered ? 0.08 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }

                Label {
                    text: (stackView.currentItem && stackView.currentItem.title) ? stackView.currentItem.title : qsTr("Inton Trainer")
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
                    font.weight: Icons.fontSolid.weight
                    text: Icons.faArrowLeft
                    font.pixelSize: 20
                    onClicked: stackView.pop()
                    visible: stackView.depth > 1

                    background: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: Theme.shapeMedium // MD3 medium shape token
                        color: backButton.hovered ? Theme.surfaceContainerLow(Material.theme) : "transparent"

                        // MD3 State Layer - hover effect (8% opacity)
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.onSurface(Material.theme)
                            opacity: backButton.hovered ? 0.08 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
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
            visible: settingsApi.showNavigationMenu

            Row {
                anchors.fill: parent

                // Home Tab
                Item {
                    width: parent.width / (window.trainingPageActive ? 3 : 2)
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
                                font.weight: Icons.fontSolid.weight
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

                // Advanced (training only) — opens template analysis from TrainingPage
                Item {
                    width: window.trainingPageActive ? parent.width / 3 : 0
                    height: parent.height
                    visible: window.trainingPageActive
                    clip: true

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: 64
                            height: 32
                            radius: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Theme.primaryContainer(Material.theme)

                            Text {
                                anchors.centerIn: parent
                                font.family: Icons.familySolid
                                font.weight: Icons.fontSolid.weight
                                font.pixelSize: 20
                                text: Icons.faSliders
                                color: Theme.onPrimaryContainer(Material.theme)
                            }
                        }

                        Text {
                            text: qsTr("Advanced")
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Theme.onSurface(Material.theme)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let page = stackView.currentItem;
                            if (page && page.openAdvancedTemplatePage) {
                                page.openAdvancedTemplatePage();
                            }
                        }
                    }
                }

                // Settings Tab
                Item {
                    width: parent.width / (window.trainingPageActive ? 3 : 2)
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
                                font.weight: Icons.fontSolid.weight
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
                            if (stackView.currentItem && stackView.currentItem.title !== qsTr("Settings")) {
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
                bottom: settingsApi.showNavigationMenu ? navigationBar.top : parent.bottom
                left: parent.left
                right: parent.right
            }

            initialItem: "pages/HomePage.qml"
        }
    }

    // ── Side drawer ───────────────────────────────────────────────────────
    Drawer {
        id: drawer
        width: Math.min(window.width * 0.8, 360 * AppScale.factor)
        height: window.height
        z: 2

        background: Rectangle {
            color: Theme.surface(Material.theme)
            radius: 16 * AppScale.factor
            layer.enabled: true
        }

        Flickable {
            anchors.fill: parent
            contentHeight: (drawerLayout.implicitHeight + 24) * AppScale.factor
            clip: true
            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: drawerLayout
                width: (drawer.width - 24 * AppScale.factor) / AppScale.factor
                x: 12 * AppScale.factor
                y: 12 * AppScale.factor
                spacing: 0
                transformOrigin: Item.TopLeft

                transform: Scale {
                    xScale: AppScale.factor
                    yScale: AppScale.factor
                }

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
                            page: "pages/TemplateCategoriesPage.qml",
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
                                font.weight: Icons.fontSolid.weight
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

                ItemDelegate {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    visible: !settingsApi.showNavigationMenu && window.trainingPageActive

                    contentItem: RowLayout {
                        spacing: 12
                        Text {
                            font.family: Icons.familySolid
                            font.weight: Icons.fontSolid.weight
                            text: Icons.faSliders
                            font.pixelSize: 18
                            font.bold: true
                            color: parent.parent.highlighted ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurfaceVariant(Material.theme)
                            Layout.leftMargin: 4
                        }
                        Label {
                            text: qsTr("Advanced")
                            font.pixelSize: 14
                            font.weight: parent.parent.highlighted ? Font.Bold : Font.Normal
                            color: parent.parent.highlighted ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
                            Layout.fillWidth: true
                        }
                    }

                    highlighted: false

                    background: Rectangle {
                        radius: 28
                        color: parent.highlighted ? Theme.secondaryContainer(Material.theme) : (parent.hovered ? Theme.surfaceContainerLow(Material.theme) : "transparent")
                    }

                    onClicked: {
                        let page = stackView.currentItem;
                        if (page && page.openAdvancedTemplatePage) {
                            page.openAdvancedTemplatePage();
                        }
                        drawer.close();
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 40 // Minimum spacer height
                }

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
