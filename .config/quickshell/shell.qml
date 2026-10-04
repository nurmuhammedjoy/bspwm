import Quickshell
import Quickshell.Io
import Quickshell.X11
import QtQuick
import "./components"

ShellRoot {
    id: root

    property color m3Bg: "#1d2021"
    property color m3SurfaceContainer: "#282828"
    property color m3SurfaceContainerHigh: "#3c3836"
    property color m3Primary: "#fabd2f"
    property color m3OnPrimary: "#1d2021"
    property color m3SurfaceVariant: "#504945"
    property color m3OnSurfaceVariant: "#d5c4a1"
    property color m3Error: "#fb4934"
    property color m3OnError: "#1d2021"
    property color m3Green: "#b8bb26"
    property color m3Orange: "#fe8019"

    property var workspaces: []
    property string wifiText: "--"
    property string wifiIcon: ""
    property string wxText: "Loading..."
    property string wxIcon: ""
    property string volText: "--%"
    property string volIcon: ""
    property string batText: "--%"
    property string batIcon: ""

    // Focused desktop number, 1-indexed like the pills. Falls back to 1 so
    // the capsule still draws its minimum 5 pills before the first bspwm
    // snapshot and when nothing is focused.
    readonly property int activeWorkspace: {
        for (const w of workspaces) if (w.focused) return w.num
        return 1
    }

    // Enough pills to reach the active desktop plus one, so the next
    // desktop is always clickable. Clamped between 5 and 10.
    readonly property int wsSlots: Math.min(10, Math.max(5, activeWorkspace + 1))

    // bspwm workspace feed: get_workspaces.sh rewrites workspaces.json on
    // change and FileView picks it up via inotify. No poll timer.
    Process {
        id: wsProc
        command: [Quickshell.shellPath("get_workspaces.sh")]
        running: true
        // Reached only when bspwm restarts or the script dies. The script
        // exits when quickshell exits, so nothing leaks on reload.
        onExited: wsRestartTimer.restart()
    }

    Timer {
        id: wsRestartTimer
        interval: 1000
        onTriggered: wsProc.running = true
    }

    FileView {
        id: wsFile
        path: Quickshell.shellPath("workspaces.json")
        watchChanges: true
        // The re-read is asynchronous, parse from the text below.
        onFileChanged: wsFile.reload()
        onTextChanged: {
            let parsed
            try {
                parsed = JSON.parse(wsFile.text())
            } catch (e) {
                // The feed truncates the file before writing, so a read
                // can land in that window. Keep the last state.
                return
            }
            root.workspaces = parsed
        }
    }

    Process {
        id: wifiProc
        command: ["bash", Quickshell.shellPath("svg/wifi.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                root.wifiIcon = parts[0] || ""
                root.wifiText = parts.slice(1).join(" ") || "--"
            }
        }
        onExited: wifiTimer.restart()
    }

    Timer {
        id: wifiTimer
        interval: 5000
        onTriggered: wifiProc.running = true
    }

    Process {
        id: wxProc
        command: ["bash", Quickshell.shellPath("svg/weather.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                root.wxIcon = parts[0] || ""
                root.wxText = parts.slice(1).join(" ") || "N/A"
            }
        }
        onExited: wxTimer.restart()
    }

    Timer {
        id: wxTimer
        interval: 600000
        onTriggered: wxProc.running = true
    }

    Process {
        id: volProc
        command: ["bash", Quickshell.shellPath("svg/volume.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                root.volIcon = parts[0] || ""
                root.volText = parts.slice(1).join(" ") || "--%"
            }
        }
        onExited: volTimer.restart()
    }

    Timer {
        id: volTimer
        interval: 2000
        onTriggered: volProc.running = true
    }

    Process {
        id: batProc
        command: ["bash", Quickshell.shellPath("svg/battery.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                root.batIcon = parts[0] || ""
                root.batText = parts.slice(1).join(" ") || "--%"
            }
        }
        onExited: batTimer.restart()
    }

    Timer {
        id: batTimer
        interval: 15000
        onTriggered: batProc.running = true
    }

    Variants {
        model: Quickshell.screens

        XPanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true }

            // Bar is 48px wide; the extra 22px on its right holds the
            // concave corners that blend it into the desktop.
            readonly property int barWidth: 48
            readonly property int cornerSize: 22
            implicitWidth: barWidth + cornerSize
            color: "transparent"

            // Only the visible bar reserves space. Auto would reserve the
            // full implicitWidth (70px) and leave a 22px gap next to bspwm.
            exclusiveZone: barWidth

            Rectangle {
                id: panel
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                width: barWidth
                radius: 0
                color: root.m3SurfaceContainer

                Item {
                    id: strip
                    anchors.fill: parent

                    WorkspaceColumn {
                        id: wsCol
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        workspaces: root.workspaces
                        wsSlots: root.wsSlots
                        surfaceVariant: root.m3SurfaceVariant
                        fgOnSurfaceVariant: root.m3OnSurfaceVariant
                        primaryColor: root.m3Primary
                        fgOnPrimary: root.m3OnPrimary
                        errorColor: root.m3Error
                        fgOnError: root.m3OnError
                        surfaceDim: root.m3Bg
                        trackColor: root.m3SurfaceContainerHigh
                    }

                    ClockColumn {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
                        pillColor: root.m3SurfaceContainerHigh
                        fgOnPill: root.m3OnSurfaceVariant
                    }

                    TrayColumn {
                        id: tray
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        wifiIcon: root.wifiIcon
                        wxIcon: root.wxIcon
                        volIcon: root.volIcon
                        batIcon: root.batIcon
                        batText: root.batText
                        groupColor: root.m3SurfaceContainerHigh
                        fgOnSurfaceVariant: root.m3OnSurfaceVariant
                        accentGreen: root.m3Green
                        accentYellow: root.m3Primary
                        accentRed: root.m3Error
                        // Launcher and power are not wired up yet.
                        onLauncherClicked: console.log("launcher clicked")
                        onPowerClicked: console.log("power clicked")
                    }
                }
            }

            // Concave (inverted) corners where the bar meets the desktop.
            Canvas {
                x: barWidth; y: 0
                width: cornerSize; height: cornerSize
                property color fill: root.m3SurfaceContainer
                onFillChanged: requestPaint()
                onPaint: {
                    const r = cornerSize
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = fill
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(r, 0)
                    ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            Canvas {
                x: barWidth; y: parent.height - cornerSize
                width: cornerSize; height: cornerSize
                property color fill: root.m3SurfaceContainer
                onFillChanged: requestPaint()
                onPaint: {
                    const r = cornerSize
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = fill
                    ctx.beginPath()
                    ctx.moveTo(0, r)
                    ctx.lineTo(r, r)
                    ctx.arc(r, 0, r, Math.PI / 2, Math.PI, false)
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }
    }
}
