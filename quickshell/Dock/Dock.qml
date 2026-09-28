import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
  id: root

  property int iconSize: 56
  property int spacing: 16
  property int padding: 8

  property bool triggerHovered: false
  property bool dockHovered: false
  property bool appHovered: false

  property var apps: []

  FileView {
    id: jsonFile

    path: Qt.resolvedUrl("./apps.json")
    blockLoading: true
    watchChanges: true

    onFileChanged: reload()

    onLoaded: {
      try {
        root.apps = JSON.parse(jsonFile.text())
      } catch (e) {
        console.warn("Failed to parse apps.json:", e)
      }
    }
  }

  readonly property int dockWidth:
    root.apps.length * root.iconSize
    + Math.max(root.apps.length - 1, 0) * root.spacing
    + root.padding * 2

  readonly property int dockHeight:
    root.iconSize + root.padding * 2

  property bool dockVisible: false

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quickshell-dock"
  exclusionMode: ExclusionMode.Ignore

  anchors {
    bottom: true
  }

  implicitWidth: Math.max(root.dockWidth, 200) + 10
  implicitHeight: root.dockHeight + 15

  color: "transparent"

  Rectangle {
    id: dock

    anchors {
      horizontalCenter: parent.horizontalCenter
      bottom: parent.bottom
      bottomMargin: 20
    }

    width: root.dockWidth - root.padding * 2
    height: root.dockHeight

    radius: 20
    color: "#01000000"

    opacity: root.dockVisible ? 1 : 0

    transform: Translate {
      id: dockTranslate

      y: root.dockVisible ? 0 : root.dockHeight + 20

      Behavior on y {
        NumberAnimation {
          duration: 600
          easing.type: Easing.OutCubic
        }
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: 400
        easing.type: Easing.OutCubic
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.dockVisible
      hoverEnabled: true

      onEntered: {
        root.dockHovered = true
        hideTimer.stop()
      }

      onExited: {
        root.dockHovered = false
        hideTimer.restart()
      }
    }

    Row {
      anchors.centerIn: parent

      spacing: root.spacing

      Repeater {
        model: root.apps

        delegate: DockApp {
          id: appItem
          required property string modelData

          entry: DesktopEntries.byId(modelData)
          iconSize: root.iconSize

          // Если наведены на иконку — сбрасываем таймер прятания
          onHoveredChanged: {
            if (hovered) {
              root.appHovered = true
              hideTimer.stop()
            } else {
              root.appHovered = false
              hideTimer.restart()
            }
          }
        }
      }
    }
  }

  Rectangle {
    id: trigger

    anchors {
      horizontalCenter: parent.horizontalCenter
      bottom: parent.bottom
    }

    width: Math.max(root.dockWidth * 1.1, 200)
    height: 15

    color: "transparent"

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true

      onEntered: {
        root.triggerHovered = true
        root.dockVisible = true
        hideTimer.stop()
      }

      onExited: {
        root.triggerHovered = false
        hideTimer.restart()
      }
    }
  }

  Timer {
    id: hideTimer

    interval: 400
    repeat: false

    onTriggered: {
      if (!root.triggerHovered && !root.dockHovered && !root.appHovered) {
        root.dockVisible = false
      }
    }
  }
}