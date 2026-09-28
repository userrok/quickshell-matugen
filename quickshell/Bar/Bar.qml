import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "."
import "components"
import qs


ShellRoot {
	id: barRoot

	property alias wallpaperMode: panel.wallpaperMode

	function toggleWallpaperMenu() {
		panel.wallpaperMode = !panel.wallpaperMode
	}

	PanelWindow {
		id: panel

		property bool hovered: false
		property bool wallpaperMode: false

		WlrLayershell.keyboardFocus: panel.wallpaperMode
			? WlrKeyboardFocus.Exclusive
			: WlrKeyboardFocus.None

		focusable: panel.wallpaperMode

		anchors {
			top: true
			left: true
			right: true
		}

		implicitHeight: 150
		aboveWindows: true
		exclusiveZone: 25

		margins {
			top: 10
			bottom: 5
		}

		color: "transparent"

		mask: Region {
			Region {
				x: capsule.x
				y: capsule.y
				width: capsule.width
				height: capsule.height
			}

			Region {
				x: musicPlayer.x
				y: musicPlayer.y
				width: musicPlayer.width
				height: musicPlayer.height
			}

			Region {
				x: volume.x
				y: volume.y
				width: volume.width
				height: volume.height
			}

		}

		Item {
			id: mainRow

			anchors.fill: parent

			Rectangle {
				id: capsule

				anchors.horizontalCenter: parent.horizontalCenter
				anchors.top: parent.top

				readonly property int collapsedWidth: 120
				readonly property int collapsedHeight: 40
				readonly property int expandedWidth: 300
				readonly property int expandedHeight: 120
				readonly property int wallpaperWidth: 620
				readonly property int wallpaperHeight: 175

				width: panel.wallpaperMode
					? wallpaperWidth
					: (panel.hovered ? expandedWidth : collapsedWidth)

				height: panel.wallpaperMode
					? wallpaperHeight
					: (panel.hovered ? expandedHeight : collapsedHeight)

				radius: 20
				color: Colors.md3.surface
				opacity: 0.95
				clip: true

				Behavior on width {
					NumberAnimation {
						duration: 220
						easing.type: Easing.OutCubic
					}
				}

				Behavior on height {
					NumberAnimation {
						duration: 220
						easing.type: Easing.OutCubic
					}
				}

				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					acceptedButtons: Qt.LeftButton | Qt.RightButton

					onEntered: panel.hovered = true
					onExited: panel.hovered = false

					onClicked: mouse => {
						if (mouse.button === Qt.RightButton)
							panel.wallpaperMode = !panel.wallpaperMode
					}
				}

				Clock {
					id: clock

					anchors.horizontalCenter: parent.horizontalCenter

					visible: !panel.wallpaperMode

					property real clockCenterY: panel.hovered
						? capsule.expandedHeight * 0.3
						: capsule.collapsedHeight / 2

					y: clockCenterY - height / 2

					Behavior on clockCenterY {
						NumberAnimation {
							duration: 220
							easing.type: Easing.OutCubic
						}
					}

					hovered: panel.hovered
				}

				Calendar {
					id: calendar

					expanded: panel.hovered && !panel.wallpaperMode

					anchors {
						left: parent.left
						right: parent.right
					}

					property real calendarCenterY:
						capsule.expandedHeight * 0.7

					height: 40
					y: calendarCenterY - height / 2
				}

				WallpaperMenu {
					id: wallpaperMenu

					anchors.fill: parent

					active: panel.wallpaperMode
					activeMonitor: panel.screen ? panel.screen.name : ""

					onCloseRequested: panel.wallpaperMode = false
				}
			}

			MusicPlayer {
				id: musicPlayer

				anchors.right: capsule.left
				anchors.rightMargin: 8
				anchors.top: parent.top

				visible: playerRunning
			}

			Volume {
				id: volume

				anchors.left: capsule.right
				anchors.leftMargin: 8
				anchors.top: parent.top
			}

		}
	}
}
