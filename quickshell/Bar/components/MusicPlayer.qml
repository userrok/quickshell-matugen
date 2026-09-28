// MusicPlayer.qml
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs

Item {
  id: musicPlayer

  readonly property color bgColor: Colors.md3.surface
  readonly property color fgColor: Colors.md3.on_surface
  readonly property color accent: Colors.md3.on_surface_variant

  readonly property var player: {
    const players = Mpris.players.values

    for (let i = 0; i < players.length; i++) {
      const p = players[i]
      if (p.isPlaying)
        return p
    }

    return players.length > 0 ? players[0] : null
  }

  readonly property bool playerRunning: player !== null
  readonly property bool isPlaying: player ? player.isPlaying : false

  readonly property real length: player ? (player.length || 0) : 0

  property real displayPosition: 0
  readonly property real progress: length > 0
    ? Math.min(1, displayPosition / length)
    : 0

  property bool hovered: false

  readonly property int collapsedSize: 37
  readonly property int expandedWidth: 340
  readonly property int expandedHeight: 120
  readonly property int padding: 7
  readonly property int rightPadding: 14

  implicitWidth: !playerRunning ? 0 : (hovered ? expandedWidth : collapsedSize)
  implicitHeight: !playerRunning ? 0 : (hovered ? expandedHeight : collapsedSize)

  visible: opacity > 0
  opacity: playerRunning ? 1 : 0

  Behavior on implicitWidth {
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
  }

  Behavior on implicitHeight {
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
  }

  Behavior on opacity {
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
  }

  function formatTime(sec) {
    if (!sec || sec < 0 || !isFinite(sec)) return "0:00"
    sec = Math.floor(sec)
    const m = Math.floor(sec / 60)
    const s = sec % 60
    return m + ":" + (s < 10 ? "0" + s : s)
  }

  Timer {
    interval: 1000
    repeat: true
    running: musicPlayer.playerRunning

    onTriggered: {
      const real = musicPlayer.player
        ? (musicPlayer.player.position || 0)
        : 0

      if (musicPlayer.isPlaying) {
        if (Math.abs(musicPlayer.displayPosition + 1 - real) < 2) {
          musicPlayer.displayPosition += 1
        } else {
          musicPlayer.displayPosition = real
        }

        if (musicPlayer.displayPosition > musicPlayer.length)
          musicPlayer.displayPosition = musicPlayer.length
      } else {
        musicPlayer.displayPosition = real
      }
    }
  }

  Connections {
    target: musicPlayer.player

    function onTrackTitleChanged() {
      musicPlayer.displayPosition = musicPlayer.player
        ? (musicPlayer.player.position || 0)
        : 0
    }
  }

  function seekTo(seconds) {
    if (!player) return
    player.position = seconds
    displayPosition = seconds
  }

  Rectangle {
    id: container
    anchors.fill: parent

    radius: musicPlayer.hovered ? 20 : 18.5

    Behavior on radius {
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    color: musicPlayer.bgColor
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1
    clip: true

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: musicPlayer.hovered = true
      onExited: musicPlayer.hovered = false
    }

    Item {
      id: expandedContent
      width: musicPlayer.expandedWidth
      height: musicPlayer.expandedHeight
      anchors.top: parent.top
      anchors.left: parent.left

      opacity: musicPlayer.hovered ? 1 : 0
      visible: opacity > 0.01

      Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      Rectangle {
        id: expandedAlbumContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: musicPlayer.padding
        anchors.topMargin: musicPlayer.padding
        anchors.bottomMargin: musicPlayer.padding
        width: height
        radius: 15
        color: "transparent"

        Rectangle {
          anchors.fill: parent
          radius: expandedAlbumContainer.radius
          color: musicPlayer.fgColor
          opacity: 0.15

          Text {
            anchors.centerIn: parent
            text: "♪"
            color: musicPlayer.fgColor
            font.family: "SF Pro Display"
            font.pixelSize: Math.round(parent.height * 0.4)
            font.weight: 600
          }
        }

        Image {
          anchors.fill: parent
          source: musicPlayer.player
            ? (musicPlayer.player.trackArtUrl || "")
            : ""
          fillMode: Image.PreserveAspectCrop
          smooth: true
          asynchronous: true
          cache: true
          sourceSize.width: width * 2
          sourceSize.height: height * 2

          layer.enabled: true

          layer.effect: OpacityMask {
            maskSource: Rectangle {
              width: expandedAlbumContainer.width
              height: expandedAlbumContainer.height
              radius: expandedAlbumContainer.radius
            }
          }
        }
      }

      Column {
        anchors.left: expandedAlbumContainer.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: musicPlayer.rightPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Item {
          id: titleMarquee
          width: parent.width
          height: marqueeRow.height
          clip: true

          readonly property string titleString: musicPlayer.player
            ? (musicPlayer.player.trackTitle || "Nothing Playing")
            : "Nothing Playing"

          readonly property bool overflow: titleText.implicitWidth > width
          readonly property int gap: 40

          onTitleStringChanged: {
            marqueeRow.x = 0
            if (marqueeAnim.running)
              marqueeAnim.restart()
          }

          Row {
            id: marqueeRow
            x: 0
            spacing: titleMarquee.gap

            Text {
              id: titleText
              text: titleMarquee.titleString
              color: musicPlayer.fgColor
              font.family: "SF Pro Display"
              font.pixelSize: 16
              font.bold: true
            }

            // копия для бесшовного цикла
            Text {
              visible: titleMarquee.overflow
              text: titleMarquee.titleString
              color: musicPlayer.fgColor
              font.family: "SF Pro Display"
              font.pixelSize: 16
              font.bold: true
            }
          }

          SequentialAnimation {
            id: marqueeAnim
            running: titleMarquee.overflow && musicPlayer.hovered
            loops: Animation.Infinite

            onRunningChanged: {
              if (!running)
                marqueeRow.x = 0
            }

            PauseAnimation { duration: 690 }

            NumberAnimation {
              target: marqueeRow
              property: "x"
              from: 0
              to: -(titleText.implicitWidth + titleMarquee.gap)
              duration: (titleText.implicitWidth + titleMarquee.gap) * 25
            }
          }
        }

        Text {
          width: parent.width
          text: musicPlayer.player
            ? (musicPlayer.player.trackArtist || "Unknown Artist")
            : "Unknown Artist"
          color: musicPlayer.accent
          opacity: 0.75
          font.family: "SF Pro Display"
          font.pixelSize: 14
          elide: Text.ElideRight
        }

        RowLayout {
          width: parent.width
          spacing: 6

          Text {
            text: musicPlayer.formatTime(musicPlayer.displayPosition)
            color: musicPlayer.accent
            opacity: 0.75
            font.family: "SF Pro Display"
            font.pixelSize: 11
            font.weight: 500
          }

          Rectangle {
            id: progressTrack
            Layout.fillWidth: true
            Layout.minimumWidth: 40
            Layout.preferredHeight: 4
            Layout.maximumHeight: 4
            Layout.alignment: Qt.AlignVCenter
            color: Colors.md3.outline_variant
            opacity: 0.75

            Rectangle {
              width: progressTrack.width * musicPlayer.progress
              height: progressTrack.height
              radius: progressTrack.radius
              color: musicPlayer.fgColor
              opacity: 1.0
            }

            MouseArea {
              anchors.fill: parent
              anchors.topMargin: -6
              anchors.bottomMargin: -6
              cursorShape: Qt.PointingHandCursor

              onClicked: (mouse) => {
                if (!musicPlayer.player || musicPlayer.length <= 0)
                  return

                const ratio = Math.max(
                  0,
                  Math.min(1, mouse.x / progressTrack.width)
                )

                musicPlayer.seekTo(ratio * musicPlayer.length)
              }
            }
          }

          Text {
            text: musicPlayer.formatTime(musicPlayer.length)
            color: musicPlayer.accent
            opacity: 0.75
            font.family: "SF Pro Display"
            font.pixelSize: 11
            font.weight: 500
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 20

          Text {
            text: "󰒮"
            color: musicPlayer.fgColor
            opacity: musicPlayer.player
              && musicPlayer.player.canGoPrevious ? 1 : 0.3
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor

              onClicked: {
                if (musicPlayer.player
                    && musicPlayer.player.canGoPrevious)
                  musicPlayer.player.previous()
              }
            }
          }

          Text {
            text: musicPlayer.isPlaying ? "󰏤" : "󰐊"
            color: musicPlayer.fgColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor

              onClicked: {
                if (musicPlayer.player)
                  musicPlayer.player.togglePlaying()
              }
            }
          }

          Text {
            text: "󰒭"
            color: musicPlayer.fgColor
            opacity: musicPlayer.player
              && musicPlayer.player.canGoNext ? 1 : 0.3
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor

              onClicked: {
                if (musicPlayer.player
                    && musicPlayer.player.canGoNext)
                  musicPlayer.player.next()
              }
            }
          }
        }
      }
    }

    Item {
      id: collapsedAlbum
      z: 1
      width: 31
      height: 31
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: 3
      anchors.topMargin: 3

      opacity: musicPlayer.hovered ? 0 : 1
      visible: opacity > 0.01

      Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: musicPlayer.fgColor
        opacity: 0.15

        Text {
          anchors.centerIn: parent
          text: "♪"
          color: musicPlayer.fgColor
          font.family: "SF Pro Display"
          font.pixelSize: 14
          font.weight: 600
        }
      }

      Image {
        anchors.fill: parent
        source: musicPlayer.player
          ? (musicPlayer.player.trackArtUrl || "")
          : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
        sourceSize.width: 62
        sourceSize.height: 62

        layer.enabled: true

        layer.effect: OpacityMask {
          maskSource: Rectangle {
            width: collapsedAlbum.width
            height: collapsedAlbum.height
            radius: collapsedAlbum.width / 2
          }
        }
      }
    }
  }
}