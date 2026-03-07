import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import "../utils"

Button {
    id: control
    property string iconText: ""
    property bool primary: false

    implicitWidth: 56
    implicitHeight: 56

    contentItem: Text {
        text: control.iconText
        font.family: Icons.familySolid
        font.pixelSize: 24
        color: control.primary ? Theme.onPrimary(Material.theme) : Theme.onSurface(Material.theme)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on font.pixelSize {
            NumberAnimation {
                duration: 100
            }
        }
    }

    background: Rectangle {
        implicitWidth: 56
        implicitHeight: 56
        radius: 28 // MD3 medium shape token
        color: control.primary ? Theme.primary(Material.theme) : Theme.surfaceContainerLow(Material.theme)

        border.color: control.primary ? "transparent" : Theme.outline(Material.theme)
        border.width: control.primary ? 0 : 1

        // MD3 State Layer - overlay for interactive states
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            
            // Hover state layer (8% opacity)
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: control.primary ? Theme.onPrimary(Material.theme) : Theme.onSurface(Material.theme)
                opacity: control.hovered && !control.pressed ? 0.08 : 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
            
            // Pressed state layer (16% opacity)
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: control.primary ? Theme.onPrimary(Material.theme) : Theme.onSurface(Material.theme)
                opacity: control.pressed ? 0.16 : 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        // MD3 Elevation shadow for primary button
        layer.enabled: control.primary
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            blur: 0.5
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    states: [
        State {
            name: "hovered"
            when: control.hovered
            PropertyChanges {
                target: control.contentItem
                font.pixelSize: 28
            }
        }
    ]
}
