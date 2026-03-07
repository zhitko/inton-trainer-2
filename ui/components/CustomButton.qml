import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material 6.8
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
        radius: 28 // MD3 pill shape
        color: control.primary ? Theme.primary(Material.theme) : (control.pressed ? Theme.surfaceContainerHighest(Material.theme) : control.hovered ? Theme.surfaceContainerHigh(Material.theme) : Theme.surfaceContainerLow(Material.theme))

        border.color: control.primary ? "transparent" : Theme.outlineVariant(Material.theme)
        border.width: control.primary ? 0 : 1

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
