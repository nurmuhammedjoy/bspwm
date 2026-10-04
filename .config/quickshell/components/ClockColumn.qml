import QtQuick
import Quickshell
import Quickshell.Io

// Hours stacked over minutes in one slim pill.
Item {
    id: root

    property color pillColor: "#b8bb26"
    property color fgOnPill: "#1d2021"

    property string germanHours: "--"
    property string germanMinutes: "--"

    Process {
        id: deClock
        command: ["sh", "-c", "TZ='Europe/Berlin' date '+%H:%M'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(":")
                if (parts.length >= 2) {
                    root.germanHours = parts[0]
                    root.germanMinutes = parts[1]
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: deClock.running = true
    }

    implicitWidth: 48
    implicitHeight: 116

    Rectangle {
        anchors.centerIn: parent
        width: 38
        height: 84
        radius: 19
        color: root.pillColor

        Column {
            anchors.centerIn: parent
            spacing: -1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.germanHours
                font.pixelSize: 19
                font.weight: Font.Bold
                font.family: "sans-serif"
                color: root.fgOnPill
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.germanMinutes
                font.pixelSize: 19
                font.weight: Font.Medium
                font.family: "sans-serif"
                color: Qt.rgba(root.fgOnPill.r, root.fgOnPill.g, root.fgOnPill.b, 0.55)
            }
        }
    }
}
