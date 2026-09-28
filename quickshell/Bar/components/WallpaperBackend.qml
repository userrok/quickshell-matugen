pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string wallpaperDir:
    Quickshell.env("HOME") + "/Wallpapers/static"

  readonly property string hyprpaperConfig:
    Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"

  property string wallpaper: ""

  property bool busy: false
  property bool daemonRunning: false
  property string lastError: ""

  property bool matugenBusy: false
  property string matugenError: ""

  property var matugenColors: []
  property bool matugenColorSelectionPending: false
  property string matugenColorPath: ""

  property string pendingWallpaper: ""

  property bool configWritePending: false

  FileView {
    id: hyprpaperConfigFile

    path: root.hyprpaperConfig
    watchChanges: false
    blockLoading: true

    onSaved: {
      root.configWritePending = false

      console.log(
        "[WallpaperBackend] hyprpaper.conf saved"
      )

      root.restartHyprpaper()
    }

    onSaveFailed: error => {
      root.configWritePending = false
      root.busy = false
      root.lastError =
        "Failed to save hyprpaper.conf"

      console.warn(
        "[WallpaperBackend] failed to save hyprpaper.conf:",
        error
      )
    }

    onLoadFailed: error => {
      root.busy = false
      root.lastError =
        "Failed to load hyprpaper.conf"

      console.warn(
        "[WallpaperBackend] failed to load hyprpaper.conf:",
        error
      )
    }
  }

  Process {
    id: daemonCheckProc

    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim()

        if (out.length > 0) {
          console.log(
            "[WallpaperBackend] hyprpaper:",
            out
          )
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        const out = text.trim()

        if (out.length > 0) {
          console.warn(
            "[WallpaperBackend] hyprpaper stderr:",
            out
          )
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        readinessPoll.stop()

        root.daemonRunning = true
        root.lastError = ""
        root.busy = false

        console.log(
          "[WallpaperBackend] hyprpaper is running"
        )

        root.applyPendingWallpaper()
        return
      }

      if (readinessPoll.running)
        return

      console.log(
        "[WallpaperBackend] hyprpaper is not running, starting it"
      )

      root.daemonRunning = false

      Quickshell.execDetached([
        "hyprpaper"
      ])

      warmupTimer.restart()
    }
  }

  Process {
    id: matugenColorsProc

    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim()

        if (out.length === 0)
          return

        const colors = out
          .split(/\r?\n/)
          .map(line => line.trim())
          .filter(line =>
            /^#[0-9a-fA-F]{6,8}$/.test(line)
          )

        if (colors.length > 0) {
          root.matugenColors = colors

          console.log(
            "[WallpaperBackend] matugen source colors:",
            JSON.stringify(colors)
          )
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        const out = text.trim()

        if (out.length > 0) {
          console.warn(
            "[WallpaperBackend] matugen colors stderr:",
            out
          )
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        root.matugenBusy = false
        root.matugenColorSelectionPending = false

        if (root.matugenColors.length === 0) {
          root.matugenError =
            "Failed to extract Matugen source colors"
        }

        console.warn(
          "[WallpaperBackend] matugen color extraction failed:",
          exitCode
        )

        return
      }

      root.matugenBusy = false

      if (root.matugenColors.length === 0) {
        root.matugenColorSelectionPending = false
        root.matugenError =
          "Matugen returned no source colors"

        console.warn(
          "[WallpaperBackend] matugen returned no source colors"
        )

        return
      }

      root.matugenError = ""
      root.matugenColorSelectionPending = true

      console.log(
        "[WallpaperBackend] waiting for matugen color selection"
      )
    }
  }

  Process {
    id: matugenProc

    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim()

        if (out.length > 0) {
          console.log(
            "[WallpaperBackend] matugen:",
            out
          )
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        const out = text.trim()

        if (out.length > 0) {
          console.warn(
            "[WallpaperBackend] matugen stderr:",
            out
          )
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        root.matugenError =
          `matugen exited with code ${exitCode}`

        console.warn(
          "[WallpaperBackend] matugen failed:",
          exitCode
        )
      } else {
        root.matugenError = ""

        console.log(
          "[WallpaperBackend] matugen theme applied"
        )
      }

      root.matugenBusy = false
      root.matugenColorSelectionPending = false
      root.matugenColors = []
      root.matugenColorPath = ""
    }
  }

  Timer {
    id: warmupTimer

    interval: 300
    repeat: false

    onTriggered: {
      readinessPoll.attempts = 0
      readinessPoll.start()
    }
  }

  Timer {
    id: readinessPoll

    interval: 200
    repeat: true

    property int attempts: 0

    onTriggered: {
      if (daemonCheckProc.running)
        return

      if (attempts >= 25) {
        stop()

        root.daemonRunning = false
        root.busy = false
        root.lastError =
          "hyprpaper didn't come up in time"

        console.warn(
          "[WallpaperBackend] hyprpaper readiness timeout"
        )

        return
      }

      attempts++

      daemonCheckProc.command = [
        "hyprctl",
        "hyprpaper",
        "listactive"
      ]

      daemonCheckProc.running = true
    }
  }

  Component.onCompleted: initializeBackend()

  function initializeBackend() {
    daemonRunning = false
    busy = true
    lastError = ""

    readinessPoll.stop()
    warmupTimer.stop()

    if (daemonCheckProc.running)
      return

    daemonCheckProc.command = [
      "hyprctl",
      "hyprpaper",
      "listactive"
    ]

    daemonCheckProc.running = true
  }

  function refreshDaemonState() {
    if (daemonCheckProc.running)
      return

    daemonCheckProc.command = [
      "hyprctl",
      "hyprpaper",
      "listactive"
    ]

    daemonCheckProc.running = true
  }

  function setWallpaper(path) {
    if (!path || path.length === 0)
      return

    wallpaper = path
    pendingWallpaper = path

    busy = true
    lastError = ""

    console.log(
      "[WallpaperBackend] setting wallpaper:",
      path
    )

    writeHyprpaperConfig(
      path
    )
  }

  function applyPendingWallpaper() {
    if (pendingWallpaper.length === 0)
      return

    const path = pendingWallpaper

    pendingWallpaper = ""

    wallpaper = path

    console.log(
      "[WallpaperBackend] wallpaper applied:",
      path
    )
  }

  function writeHyprpaperConfig(path) {
    if (configWritePending) {
      console.warn(
        "[WallpaperBackend] config write already pending"
      )
      return
    }

    if (!hyprpaperConfigFile.loaded) {
      hyprpaperConfigFile.reload()
      return
    }

    const current = hyprpaperConfigFile.text()

    const updated = updateWallpaperBlock(
      current,
      path
    )

    if (updated === current) {
      console.log(
        "[WallpaperBackend] hyprpaper.conf already up to date"
      )

      restartHyprpaper()
      return
    }

    configWritePending = true

    console.log(
      "[WallpaperBackend] writing hyprpaper.conf"
    )

    hyprpaperConfigFile.setText(updated)
  }

  function updateWallpaperBlock(config, path) {
    const normalizedPath =
      path.startsWith("/")
        ? path
        : wallpaperDir + "/" + path

    const wallpaperBlock =
      "wallpaper {\n" +
      "    monitor =\n" +
      "    path = " + normalizedPath + "\n" +
      "    fit_mode = cover\n" +
      "}"

    const blockRegex =
      /wallpaper\s*\{[\s\S]*?\}/

    if (blockRegex.test(config)) {
      return config.replace(
        blockRegex,
        wallpaperBlock
      )
    }

    let result = config.trimEnd()

    if (result.length > 0)
      result += "\n\n"

    result += wallpaperBlock + "\n"

    return result
  }

  function restartHyprpaper() {
    busy = true
    daemonRunning = false

    readinessPoll.stop()
    warmupTimer.stop()

    console.log(
      "[WallpaperBackend] restarting hyprpaper"
    )

    Quickshell.execDetached([
      "sh",
      "-c",
      "pkill -x hyprpaper; " +
      "for i in $(seq 1 50); do pgrep -x hyprpaper >/dev/null 2>&1 || break; sleep 0.02; done; " +
      "exec hyprpaper"
    ])

    warmupTimer.restart()

    requestMatugenColors(wallpaper)
  }

  function requestMatugenColors(path) {
    if (!path || path.length === 0)
      return

    if (matugenColorsProc.running)
      matugenColorsProc.running = false

    if (matugenProc.running)
      matugenProc.running = false

    matugenColors = []
    matugenColorPath = path
    matugenColorSelectionPending = false
    matugenBusy = true
    matugenError = ""

    console.log(
      "[WallpaperBackend] requesting Matugen source colors:",
      path
    )

    extractMatugenColors(path)
  }

  function extractMatugenColors(path) {
    matugenColorsProc.command = [
      "matugen",
      "image",
      path,
      "--show-source-colors"
    ]

    matugenColorsProc.running = true
  }

  function applyMatugenColor(index) {
    if (!matugenColorSelectionPending)
      return

    if (matugenProc.running)
      return

    if (
      index < 0 ||
      index >= matugenColors.length
    ) {
      console.warn(
        "[WallpaperBackend] invalid Matugen color index:",
        index
      )
      return
    }

    if (
      !matugenColorPath ||
      matugenColorPath.length === 0
    ) {
      console.warn(
        "[WallpaperBackend] no wallpaper associated with Matugen selection"
      )
      return
    }

    const path = matugenColorPath

    matugenBusy = true
    matugenError = ""
    matugenColorSelectionPending = false

    console.log(
      "[WallpaperBackend] applying Matugen color:",
      matugenColors[index],
      "index:",
      index
    )

    matugenProc.command = [
      "matugen",
      "image",
      path,
      "--source-color-index",
      String(index)
    ]

    matugenProc.running = true
  }

  function cancelMatugenColorSelection() {
    if (!matugenColorSelectionPending)
      return

    console.log(
      "[WallpaperBackend] Matugen color selection cancelled"
    )

    matugenColorSelectionPending = false
    matugenColors = []
    matugenColorPath = ""
    matugenBusy = false
    matugenError = ""
  }
}
