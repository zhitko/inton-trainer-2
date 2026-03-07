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
    implicitHeight: 32
    radius: Theme.shapeMedium
    
    // Color based on selection state
    color: selected ? Theme.secondaryContainer(Material.theme) : Theme.surfaceContainerLow(Material.theme)
    border.color: selected ? "transparent" : Theme.outline(Material.theme)
    border.width: selected ? 0 : 1
    
    // MD3 Elevation 0 (no shadow for chips)
    layer.enabled: false
    
    // MD3 State Layer - hover effect (8% opacity)
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.onSurface(Material.theme)
        opacity: mouseArea.containsMouse && chip.enabled ? 0.08 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8
        
        // Icon (optional)
        Text {
            visible: chip.icon !== ""
            text: chip.icon
            font.family: Icons.familySolid
            font.pixelSize: 18
            color: selected ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
            Layout.leftMargin: 8
        }
        
        // Text label
        Text {
            text: chip.text
            font.pixelSize: 14
            font.weight: Font.Medium
            color: selected ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
            Layout.fillWidth: true
        }
        
        // Delete button (optional)
        Text {
            visible: chip.deletable
            text: Icons.faXmark
            font.family: Icons.familySolid
            font.pixelSize: 16
            color: selected ? Theme.onSecondaryContainer(Material.theme) : Theme.onSurface(Material.theme)
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: chip.deleted()
            }
            
            Layout.rightMargin: 8
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
