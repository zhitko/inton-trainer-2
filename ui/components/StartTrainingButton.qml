pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import "../utils"

Item {
    id: root

    property alias text: label.text
    signal clicked

    readonly property real buttonSize: Math.max(96, Math.min(height * 0.92, width * (showSideWaves ? 0.48 : 0.72), 220))
    readonly property real sizeScale: buttonSize / 200
    readonly property bool showSideWaves: !AppScale.isCompact && !AppScale.isNarrow

    property var waveHeights: [64, 44, 28, 20, 32, 20, 40, 24, 20, 4, 10, 4]

    Row {
        id: leftWave
        visible: root.showSideWaves
        anchors.verticalCenter: buttonBox.verticalCenter
        anchors.right: buttonBox.left
        anchors.rightMargin: Math.round(8 * root.sizeScale)
        spacing: Math.max(2, Math.round(4 * root.sizeScale))
        layoutDirection: Qt.RightToLeft

        Repeater {
            model: root.waveHeights
            Rectangle {
                id: leftWaveBar
                required property int index
                required property int modelData
                width: Math.max(2, Math.round(4 * root.sizeScale))
                height: leftWaveBar.modelData * root.sizeScale
                radius: 2
                color: Theme.secondary(Material.theme)
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8 - (leftWaveBar.index * 0.05)

                SequentialAnimation on height {
                    running: startButtonMouseArea.containsMouse
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: leftWaveBar.modelData * root.sizeScale * 1.3
                        duration: 600 + (leftWaveBar.index * 40)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: leftWaveBar.modelData * root.sizeScale
                        duration: 600 + (leftWaveBar.index * 40)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Item {
        id: buttonBox
        width: root.buttonSize
        height: root.buttonSize
        anchors.centerIn: parent

        Rectangle {
            id: buttonGlow
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: width / 2
            color: "transparent"
            opacity: 0

            layer.enabled: startButtonMouseArea.containsMouse
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.3)
                blur: 0.8
                shadowVerticalOffset: 8
                shadowHorizontalOffset: 0
            }
        }

        Rectangle {
            id: mainButtonBg
            anchors.fill: parent
            radius: width / 2
            scale: startButtonMouseArea.pressed ? 0.95 : (startButtonMouseArea.containsMouse ? 1.05 : 1.0)

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Theme.primary(Material.theme)
                }
                GradientStop {
                    position: 1.0
                    color: Theme.primary(Material.theme)
                }
            }

            MouseArea {
                id: startButtonMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.clicked()
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: Math.max(2, Math.round(4 * root.sizeScale))

                Repeater {
                    model: [4, 8, 12, 20, 32, 52, 84, 52, 32, 20, 12, 8, 4]
                    Rectangle {
                        id: innerBar
                        required property int index
                        required property int modelData
                        width: Math.max(2, Math.round(4 * root.sizeScale))
                        height: innerBar.modelData * root.sizeScale
                        radius: 2
                        color: Theme.onPrimary(Material.theme)
                        opacity: 0.2
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on height {
                            running: startButtonMouseArea.containsMouse
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: innerBar.modelData * root.sizeScale * 1.5
                                duration: 500 + (innerBar.index * 50)
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: innerBar.modelData * root.sizeScale
                                duration: 500 + (innerBar.index * 50)
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }

            Label {
                id: label
                anchors.centerIn: parent
                width: buttonBox.width * 0.78
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.onPrimary(Material.theme)
                font.bold: true
                font.pixelSize: AppScale.fs(root.buttonSize >= 170 ? 18 : (root.buttonSize >= 130 ? 15 : 13))
            }
        }
    }

    Row {
        visible: root.showSideWaves
        anchors.verticalCenter: buttonBox.verticalCenter
        anchors.left: buttonBox.right
        anchors.leftMargin: Math.round(8 * root.sizeScale)
        spacing: Math.max(2, Math.round(4 * root.sizeScale))

        Repeater {
            model: root.waveHeights
            Rectangle {
                id: rightWaveBar
                required property int index
                required property int modelData
                width: Math.max(2, Math.round(4 * root.sizeScale))
                height: rightWaveBar.modelData * root.sizeScale
                radius: 2
                color: Theme.secondary(Material.theme)
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8 - (rightWaveBar.index * 0.05)

                SequentialAnimation on height {
                    running: startButtonMouseArea.containsMouse
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: rightWaveBar.modelData * root.sizeScale * 1.3
                        duration: 600 + (rightWaveBar.index * 40)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: rightWaveBar.modelData * root.sizeScale
                        duration: 600 + (rightWaveBar.index * 40)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }
}
