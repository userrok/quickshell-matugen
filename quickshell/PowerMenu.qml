import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: root

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "#80000000"

  Process {
    id: runner
    onExited: Qt.quit()
  }

  function runCmd(cmd) {
    runner.command = ["bash", "-c", cmd];
    runner.running = true;
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Qt.quit()
  }

  ListModel {
    id: powerActions
    ListElement { name: "Suspend"; cmd: "rm -rf /home/tealover/Pictures/Screenshots/*; hyprlock & sleep 1 && systemctl suspend" }
    ListElement { name: "Hibernate"; cmd: "rm -rf /home/tealover/Pictures/Screenshots/*; hyprlock & sleep 1 && systemctl hibernate" }
    ListElement { name: "Logout"; cmd: "rm -rf /home/tealover/Pictures/Screenshots/*; hyprshutdown -t 'Logout...'" }
    ListElement { name: "Reboot"; cmd: "rm -rf /home/tealover/Pictures/Screenshots/*; hyprshutdown -t 'Reboot...' --post-cmd 'reboot'"; detached: true }
    ListElement { name: "Shutdown"; cmd: "rm -rf /home/tealover/Pictures/Screenshots/*; hyprshutdown -t 'Shutdown...' --post-cmd 'poweroff'"; detached: true }
  }

  Rectangle {
    id: container
    width: 420
    height: 285
    anchors.centerIn: parent

    color: Colors.md3.surface_container
    radius: 25

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      Text {
        text: "Select an action"
        color: Colors.md3.primary
        font.pixelSize: 16
        font.bold: true
        Layout.leftMargin: 4
      }

      ListView {
        id: actionList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        focus: true

        model: powerActions

        Keys.onPressed: (event) => {
          if (event.key === Qt.Key_Escape) {
            Qt.quit();
          } else if (event.nativeScanCode === 39) {
            actionList.incrementCurrentIndex();
            event.accepted = true;
          } else if (event.nativeScanCode === 25) {
            actionList.decrementCurrentIndex();
            event.accepted = true;
          } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
            if (actionList.currentItem) {
              actionList.currentItem.execute();
            }
            event.accepted = true;
          }
        }

        delegate: Rectangle {
          id: delegateRoot
          width: actionList.width
          height: 40
          radius: 6

          property bool isSelected: ListView.isCurrentItem
          color: isSelected 
            ? Colors.md3.secondary_container 
            : (mouseArea.containsMouse ? Colors.md3.surface_container_high : "transparent")

          function execute() {
            if (model.detached === true) {
              Quickshell.execDetached(["bash", "-c", model.cmd]);
            } else {
              root.runCmd(model.cmd)
            }
          }

          Text {
            anchors.fill: parent
            anchors.leftMargin: 12
            verticalAlignment: Text.AlignVCenter
            text: model.name
            color: delegateRoot.isSelected ? Colors.md3.on_secondary_container : Colors.md3.on_surface
            font.pixelSize: 15
            font.bold: delegateRoot.isSelected
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              actionList.currentIndex = index;
              delegateRoot.execute();
            }
          }
        }
      }
    }
  }
}