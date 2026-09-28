import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs

Item {
  id: root

  property bool active: false
  property string activeMonitor: ""

  signal closeRequested()

  opacity: active ? 1 : 0
  visible: opacity > 0

  Behavior on opacity {
    NumberAnimation {
      duration: 220
      easing.type: Easing.OutCubic
    }
  }

  onActiveChanged: {
    if (active)
      list.forceActiveFocus()
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.active

    onActivated: {
      if (WallpaperBackend.matugenColorSelectionPending) {
        WallpaperBackend.cancelMatugenColorSelection()
        return
      }

      root.closeRequested()
    }
  }

  Shortcut {
    sequences: ["Left", "A"]
    enabled: root.active

    onActivated: {
      if (WallpaperBackend.matugenColorSelectionPending)
        return

      if (list.currentIndex > 0) {
        list.currentIndex--
      } else if (wallpaperFolder.count > 0) {
        list.currentIndex = wallpaperFolder.count - 1
      }
    }
  }

  Shortcut {
    sequences: ["Right", "D"]
    enabled: root.active

    onActivated: {
      if (WallpaperBackend.matugenColorSelectionPending)
        return

      if (list.currentIndex < wallpaperFolder.count - 1) {
        list.currentIndex++
      } else if (wallpaperFolder.count > 0) {
        list.currentIndex = 0
      }
    }
  }

  Shortcut {
    sequence: "Return"
    enabled: root.active

    onActivated: {
      if (WallpaperBackend.matugenColorSelectionPending)
        return

      const item = list.currentItem

      if (!item)
        return

      WallpaperBackend.setWallpaper(
        item.filePath,
        root.activeMonitor
      )
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 10

    spacing: 8

    Text {
      Layout.fillWidth: true

      visible:
        WallpaperBackend.busy
        || WallpaperBackend.matugenBusy
        || WallpaperBackend.lastError.length > 0
        || WallpaperBackend.matugenError.length > 0

      text:
        WallpaperBackend.lastError.length > 0
          ? WallpaperBackend.lastError
          : WallpaperBackend.matugenError.length > 0
            ? WallpaperBackend.matugenError
            : WallpaperBackend.busy
              ? "Applying…"
              : "Generating theme…"

      color:
        (
          WallpaperBackend.lastError.length > 0
          || WallpaperBackend.matugenError.length > 0
        )
          ? Colors.md3.error
          : Colors.md3.on_surface_variant

      font.pixelSize: 10
      font.weight: Font.Medium
      elide: Text.ElideRight
    }

    FolderListModel {
      id: wallpaperFolder

      folder: "file://" + WallpaperBackend.wallpaperDir

      nameFilters: [
        "*.png",
        "*.jpg",
        "*.jpeg",
        "*.webp",
        "*.jxl",
        "*.PNG",
        "*.JPG",
        "*.JPEG",
        "*.WEBP",
        "*.JXL"
      ]

      sortField: FolderListModel.Name
    }

    Text {
      Layout.fillWidth: true

      visible: wallpaperFolder.count === 0

      text: "Not found in " + WallpaperBackend.wallpaperDir

      color: Colors.md3.on_surface_variant
      font.pixelSize: 10

      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }

    ListView {
      id: list

      Layout.fillWidth: true
      Layout.preferredHeight: 78

      visible:
        wallpaperFolder.count > 0
        && !WallpaperBackend.matugenColorSelectionPending

      clip: true
      focus: true

      orientation: ListView.Horizontal
      spacing: 10

      model: wallpaperFolder

      property int itemWidth: 96
      property int itemHeight: 72

      preferredHighlightBegin:
        (width - itemWidth) / 2

      preferredHighlightEnd:
        (width + itemWidth) / 2

      highlightRangeMode:
        ListView.StrictlyEnforceRange

      highlightMoveDuration: 200

      leftMargin:
        (width - itemWidth) / 2

      rightMargin:
        (width - itemWidth) / 2

      delegate: Item {
        id: cell

        required property string fileName
        required property string filePath
        required property url fileUrl
        required property int index

        width: list.itemWidth
        height: list.itemHeight

        property bool isCurrent:
          WallpaperBackend.wallpaper === cell.filePath

        property bool isSelected:
          list.currentIndex === cell.index

        Rectangle {
          id: card

          anchors.fill: parent

          radius: 8
          clip: true

          border.width:
            (cell.isCurrent || cell.isSelected)
              ? 2
              : 1

          border.color:
            cell.isSelected
              ? Colors.md3.primary
              : (
                  cell.isCurrent
                    ? Colors.md3.secondary
                    : Colors.md3.outline_variant
                )

          scale: cell.isSelected ? 1.05 : 0.95

          Behavior on scale {
            NumberAnimation {
              duration: 150
              easing.type: Easing.OutCubic
            }
          }

          Behavior on border.color {
            ColorAnimation {
              duration: 150
            }
          }

          Image {
            anchors.fill: parent
            anchors.margins: card.border.width

            source: cell.fileUrl

            fillMode: Image.PreserveAspectCrop

            asynchronous: true
            cache: true
            smooth: true
          }
        }

        MouseArea {
          anchors.fill: parent

          cursorShape: Qt.PointingHandCursor

          enabled:
            !WallpaperBackend.matugenColorSelectionPending

          onClicked: {
            list.currentIndex = cell.index

            WallpaperBackend.setWallpaper(
              cell.filePath,
              root.activeMonitor
            )
          }

          onWheel: function(wheel) {
            wheel.accepted = true

            if (wheel.angleDelta.y < 0) {
              if (list.currentIndex < wallpaperFolder.count - 1) {
                list.currentIndex++
              } else {
                list.currentIndex = 0
              }
            } else if (wheel.angleDelta.y > 0) {
              if (list.currentIndex > 0) {
                list.currentIndex--
              } else {
                list.currentIndex = wallpaperFolder.count - 1
              }
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true

      visible: WallpaperBackend.matugenColorSelectionPending

      spacing: 8

      Text {
        text: "Color"

        color: Colors.md3.on_surface
        font.pixelSize: 10
        font.weight: Font.Medium
      }

      ListView {
        id: colorList

        Layout.fillWidth: true
        Layout.preferredHeight: 32

        orientation: ListView.Horizontal
        spacing: 8
        clip: true

        model: WallpaperBackend.matugenColors

        delegate: Item {
          id: colorCell

          required property string modelData
          required property int index

          width: 32
          height: 32

          Rectangle {
            id: colorButton

            anchors.centerIn: parent

            width: 28
            height: 28

            radius: 14

            color: colorCell.modelData

            border.width:
              colorMouse.containsMouse ? 2 : 1

            border.color:
              colorMouse.containsMouse
                ? Colors.md3.on_surface
                : Colors.md3.outline

            scale:
              colorMouse.containsMouse ? 1.1 : 1.0

            Behavior on scale {
              NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
              }
            }

            MouseArea {
              id: colorMouse

              anchors.fill: parent

              hoverEnabled: true

              cursorShape: Qt.PointingHandCursor

              onClicked:
                WallpaperBackend.applyMatugenColor(
                  colorCell.index
                )

              ToolTip.visible: containsMouse
              ToolTip.text: colorCell.modelData
            }
          }
        }
      }

      Button {
        id: cancelMatugenBtn

        text: "Cancel"

        implicitHeight: 28

        onClicked:
          WallpaperBackend.cancelMatugenColorSelection()

        background: Rectangle {
          radius: 16

          color:
            cancelMouse.containsMouse
              ? Colors.md3.surface_container_highest
              : Colors.md3.surface_container_high

          border.color: Colors.md3.outline_variant
          border.width: 1

          Behavior on color {
            ColorAnimation {
              duration: 150
            }
          }
        }

        contentItem: Text {
          text: parent.text

          color:
            cancelMouse.containsMouse
              ? Colors.md3.on_error_container
              : Colors.md3.on_surface_variant

          font.pixelSize: 10
          font.weight: Font.Medium

          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter

          leftPadding: 10
          rightPadding: 10
        }

        MouseArea {
          id: cancelMouse

          anchors.fill: parent

          hoverEnabled: true

          cursorShape: Qt.PointingHandCursor

          onClicked: cancelMatugenBtn.clicked()
        }
      }
    }
  }
}
