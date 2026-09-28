pragma Singleton
import QtQuick

QtObject {
  QtObject {
    id: md3
    <* for name, color in colors *>
    readonly property color {{ name }}: "{{ color.default.hex }}"
    <* endfor *>
  }
  property alias md3: md3
}