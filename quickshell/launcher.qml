import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

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

  MouseArea {
    anchors.fill: parent
    onClicked: Qt.quit()
  }

  ScriptModel {
    id: appModel
    values: {
      let query = searchInput.text.toLowerCase().trim();
      let apps = DesktopEntries.applications.values;

      if (query === "") return apps;

      return apps.filter(app => 
        (app.name && app.name.toLowerCase().includes(query)) ||
        (app.comment && app.comment.toLowerCase().includes(query)) ||
        (app.genericName && app.genericName.toLowerCase().includes(query))
      );
    }
  }

  Rectangle {
    id: container
    width: 600
    height: 400
    anchors.centerIn: parent
    
    color: Colors.md3.surface
    radius: 12

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        color: Colors.md3.surface_container_high
        radius: 8

        TextInput {
          id: searchInput
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          verticalAlignment: TextInput.AlignVCenter
          
          font.pixelSize: 16
          color: Colors.md3.on_surface
          focus: true

          onTextChanged: {
            if (appList) appList.currentIndex = 0;
          }

          Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
              Qt.quit();
            } else if ((event.nativeScanCode === 39 && (event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Down)) {
              appList.incrementCurrentIndex();
              event.accepted = true;
            } else if ((event.nativeScanCode === 25 && (event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Up)) {
              appList.decrementCurrentIndex();
              event.accepted = true;
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
              if (appList.currentItem) {
                appList.currentItem.launch();
              }
              event.accepted = true;
            }
          }
        }
      }

      ListView {
        id: appList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4

        model: appModel

        delegate: Rectangle {
          id: delegateRoot
          width: appList.width
          height: 44
          radius: 6

          property bool isSelected: ListView.isCurrentItem
          color: isSelected 
            ? Colors.md3.secondary_container 
            : (mouseArea.containsMouse ? Colors.md3.surface_container : "transparent")

          function launch() {
            if (modelData) {
              modelData.execute();
              Qt.quit();
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            IconImage {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              source: Quickshell.iconPath(modelData ? (modelData.icon || "application-x-executable") : "application-x-executable", true)
            }

            Text {
              Layout.fillWidth: true
              text: modelData ? modelData.name : ""
              color: delegateRoot.isSelected ? Colors.md3.on_secondary_container : Colors.md3.on_surface
              font.pixelSize: 14
              font.bold: delegateRoot.isSelected
              elide: Text.ElideRight
            }
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: delegateRoot.launch()
          }
        }
      }
    }
  }
}