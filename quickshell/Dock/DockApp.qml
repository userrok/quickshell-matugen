import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
  id: root

  required property var entry
  property int iconSize: 56
  
  readonly property bool hovered: mouseArea.containsMouse

  width: iconSize
  height: iconSize

  IconImage {
    id: icon

    anchors.centerIn: parent

    width: root.iconSize
    height: root.iconSize

    scale: mouseArea.containsMouse ? 1.25 : 1.0

    Behavior on scale {
      NumberAnimation {
        duration: 180
        easing.type: Easing.OutCubic
      }
    }

    source: Quickshell.iconPath(root.entry.icon || "application-x-executable", true)
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      root.entry.execute()
    }
  }
}