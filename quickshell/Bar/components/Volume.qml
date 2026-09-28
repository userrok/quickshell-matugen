// Volume.qml
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs

Rectangle {
  id: volumeCapsule


  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool sinkReady: sink !== null && sink.ready && sink.audio !== null
  readonly property real volume: sinkReady ? sink.audio.volume : 0
  readonly property bool muted: sinkReady ? sink.audio.muted : true
  readonly property int volumePercent: Math.round(volume * 100)

  PwObjectTracker {
    objects: volumeCapsule.sink ? [volumeCapsule.sink] : []
  }

  function setVolume(v) {
    if (!sinkReady) return
    sink.audio.volume = Math.max(0, Math.min(1, v))
  }

  function step(delta) {
    setVolume(volume + delta)
  }

  function toggleMute() {
    if (!sinkReady) return
    sink.audio.muted = !sink.audio.muted
  }

  property bool hovered: false
  property bool dragging: false

  readonly property int collapsedWidth: 44
  readonly property int collapsedHeight: 40
  readonly property int expandedWidth: 150

  width: (hovered || dragging) ? expandedWidth : collapsedWidth
  height: collapsedHeight
  radius: height / 2
  color: Colors.md3.surface
  opacity: 0.95
  clip: true

  Behavior on width {
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
  }

  MouseArea {
    id: hoverArea

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    onEntered: volumeCapsule.hovered = true
    onExited: volumeCapsule.hovered = false

    onClicked: volumeCapsule.toggleMute()

    onWheel: wheel => {
      volumeCapsule.step(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
    }
  }

  Row {
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 8

    Canvas {
      id: speakerIcon

      width: 16
      height: 16
      anchors.verticalCenter: parent.verticalCenter

      readonly property color iconColor: volumeCapsule.muted
        ? Colors.md3.error
        : Colors.md3.on_background

      onIconColorChanged: requestPaint()

      Connections {
        target: volumeCapsule
        function onVolumeChanged() { speakerIcon.requestPaint() }
        function onMutedChanged() { speakerIcon.requestPaint() }
      }

      onPaint: {
        let ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = iconColor
        ctx.fillStyle = iconColor
        ctx.lineWidth = 1.4
        ctx.lineCap = "round"

        ctx.beginPath()
        ctx.moveTo(1, 6)
        ctx.lineTo(5, 6)
        ctx.lineTo(9, 2)
        ctx.lineTo(9, 14)
        ctx.lineTo(5, 10)
        ctx.lineTo(1, 10)
        ctx.closePath()
        ctx.fill()

        if (volumeCapsule.muted) {
          ctx.beginPath()
          ctx.moveTo(11, 4)
          ctx.lineTo(15, 12)
          ctx.moveTo(15, 4)
          ctx.lineTo(11, 12)
          ctx.stroke()
        } else {
          let v = volumeCapsule.volume
          if (v > 0.02) {
            ctx.beginPath()
            ctx.arc(9, 8, 3, -0.6, 0.6)
            ctx.stroke()
          }
          if (v > 0.4) {
            ctx.beginPath()
            ctx.arc(9, 8, 5.5, -0.6, 0.6)
            ctx.stroke()
          }
          if (v > 0.75) {
            ctx.beginPath()
            ctx.arc(9, 8, 8, -0.6, 0.6)
            ctx.stroke()
          }
        }
      }
    }

    Item {
      width: parent.width - speakerIcon.width - parent.spacing
      height: parent.height
      visible: volumeCapsule.width > volumeCapsule.collapsedWidth + 10
      opacity: (volumeCapsule.hovered || volumeCapsule.dragging) ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: 140 }
      }

      Text {
        id: percentLabel

        anchors.verticalCenter: parent.verticalCenter
        text: volumeCapsule.muted ? "mute" : volumeCapsule.volumePercent + "%"
        color: volumeCapsule.muted ? Colors.md3.error : Colors.md3.on_background

        font {
          family: "SF Pro Display"
          pixelSize: 12
          weight: 600
        }
      }

      Rectangle {
        id: track

        anchors.left: percentLabel.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        height: 4
        radius: 2
        color: Colors.md3.on_background
        opacity: 0.25

        Rectangle {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          height: parent.height
          radius: parent.radius
          width: parent.width * volumeCapsule.volume
          color: volumeCapsule.muted ? Colors.md3.error : Colors.md3.on_background
          opacity: 1
        }

        MouseArea {
          anchors.fill: parent
          anchors.margins: -8

          onPressed: mouse => {
            volumeCapsule.dragging = true
            volumeCapsule.setVolume(mouse.x / track.width)
          }
          onPositionChanged: mouse => {
            if (pressed) volumeCapsule.setVolume(mouse.x / track.width)
          }
          onReleased: volumeCapsule.dragging = false
        }
      }
    }
  }
}
