// Clock.qml
import Quickshell
import QtQuick
import qs

Text {
  id: clockText

  property bool hovered: false

  text: Qt.formatDateTime(clock.date, "HH:mm")
  color: Colors.md3.on_background

  font {
    family: "SF Pro Display"
    letterSpacing: 2
    pixelSize: hovered ? 26 : 16
    weight: 600
  }

  Behavior on font.pixelSize {
    NumberAnimation {
      duration: 220
      easing.type: Easing.OutCubic
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}