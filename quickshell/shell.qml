import Quickshell
import Quickshell.Hyprland
import QtQuick

import "Bar"
// import "Dock"

ShellRoot {
  Bar {
    id: bar
  }

  GlobalShortcut {
    name: "wallpaper-menu"
    description: "Open wallpaper menu"

    onPressed: {
      bar.toggleWallpaperMenu()
    }
  }

  // Dock {}
}
