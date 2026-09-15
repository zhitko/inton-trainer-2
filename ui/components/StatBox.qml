import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import QtQuick.Effects
import "../utils"

Rectangle {
    id: root

    property string title: ""
    property string value: ""
    property string icon: ""
    property string iconFamily: Icons.familySolid

    color: Theme.secondaryContainer(Material.theme)
    radius: 12

    implicitWidth: 100
    implicitHeight: 100

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.15)
        blur: 0.34
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: Icons.familySolid
            font.weight: Font.Black
            font.pixelSize: AppScale.fs(root.height < 90 ? 18 : 22)
            color: Theme.primary(Material.theme)
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: root.width - 12
            text: root.title
            font.pixelSize: AppScale.fs(12)
            fontSizeMode: Text.Fit
            minimumPixelSize: 8
            color: Theme.onSecondaryContainer(Material.theme)
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.value
            font.pixelSize: AppScale.fs(root.height < 90 ? 14 : 16)
            fontSizeMode: Text.Fit
            minimumPixelSize: 10
            font.weight: 600
            color: Theme.onSurface(Material.theme)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
