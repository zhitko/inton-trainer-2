import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 412
    height: 732
    visible: true
    title: qsTr("Inton Trainer")

    header: ToolBar {
        contentHeight: 56

        Button {
            id: menuButton
            icon.source: "../res/icons/menu.svg"
            width: parent.height
            height: parent.height
            hoverEnabled: true
            onClicked: drawer.open()

            background: Rectangle {
                color: "transparent"
            }

            scale: menuButton.hovered ? 2.2 : 2.0

            transitions: Transition {
                NumberAnimation {
                    property: "scale"
                    duration: 100
                }
            }
        }

        Label {
            text: "Inton Trainer"
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

            Label {
                text: "Menu"
                font.pixelSize: 24
                padding: 10
            }
            ItemDelegate {
                text: "Home"
                width: parent.width - parent.padding
                onClicked: {
                    stackView.pop()
                    drawer.close()
                }
            }
            ItemDelegate {
                text: "Recording"
                width: parent.width - parent.padding
                onClicked: {
                    stackView.push("pages/RecordingPage.qml")
                    drawer.close()
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
        currentIndex: stackView.depth > 1 ? 1 : 0
        onCurrentIndexChanged: {
            if (currentIndex === 0) {
                stackView.pop()
            }
        }

        TabButton {
            id: homeTabButton
            padding: 10
            text: "Home"
            icon.source: "../res/icons/home.svg"
            onClicked: stackView.push("pages/HomePage.qml")
        }
        TabButton {
            text: "Recording"
            padding: homeTabButton.padding
            onClicked: stackView.push("pages/RecordingPage.qml")
        }
    }
}
