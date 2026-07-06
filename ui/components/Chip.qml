import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material 6.8
import QtQuick.Effects
import "../utils"

Rectangle {
    id: chip

    // Properties
    property string text: ""
    property string icon: ""
    property bool selected: false
    property bool deletable: false
    property bool enabled: true

    signal clicked
    signal deleted

    // MD3 Chip styling
    implicitWidth: layout.implicitWidth + 16
    implicitHeight: 35
    radius: Theme.shapeExtraSmall

    // Color based on selection state
    color: selected ? Theme.secondaryContainer(Material.theme) : Theme.surfaceContainerHigh(Material.theme)
    border.color: selected ? "transparent" : Theme.outline(Material.theme)
    border.width: selected ? 0 : 1

    // MD3 Elevation 0 (no shadow for chips)
    layer.enabled: false

    // MD3 State Layer - hover / pressed effect
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.onSurface(Material.theme)
        opacity: chip.enabled ? (mouseArea.pressed ? 0.12 : mouseArea.containsMouse ? 0.08 : 0) : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8
        Layout.alignment: Qt.AlignVCenter

        // Icon (optional)
        Text {
            visible: chip.icon !== ""
            text: chip.icon
            font.family: Icons.familySolid
            font.weight: 900
            font.pixelSize: AppScale.fs(14)
            color: selected ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
            Layout.alignment: Qt.AlignVCenter
        }

        // Text label
        Text {
            text: chip.text
            font.pixelSize: AppScale.fs(12)
            font.weight: Font.Medium
            color: selected ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Delete button (optional)
        Text {
            visible: chip.deletable
            text: Icons.faXmark
            font.family: Icons.familySolid
            font.weight: Font.Black
            font.pixelSize: AppScale.fs(14)
            color: selected ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: chip.deleted()
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: chip.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: chip.enabled
        onClicked: chip.clicked()
        hoverEnabled: true
    }
}
