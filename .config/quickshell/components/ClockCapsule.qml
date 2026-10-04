import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property color surfaceContainer: "#282828"
    property color primaryColor: "#fabd2f"
    property color fgOnSurfaceVariant: "#d5c4a1"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    property string germanTime: "--:--"

    Process {
        id: deClock
        command: ["sh", "-c", "TZ='Europe/Berlin' date +%H:%M"]
        stdout: StdioCollector {
            onStreamFinished: root.germanTime = text.trim()
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: deClock.running = true
    }

    height: 32
    width: clockRow.implicitWidth + 10
    radius: 16
    color: surfaceContainer
    border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.18)
    border.width: 1

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 10
        rightPadding: 6

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 24
            width: timeText.implicitWidth + 16
            radius: 12
            color: root.primaryColor

            Text {
                id: timeText
                anchors.centerIn: parent
                text: "%1:%2".arg(clock.hours.toString().padStart(2, "0")).arg(clock.minutes.toString().padStart(2, "0"))
                font.pixelSize: 12
                font.weight: Font.Black
                font.family: "sans-serif"
                color: root.surfaceContainer
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: clock.date.toLocaleString(Qt.locale("C"), "ddd, MMM d").toUpperCase()
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.family: "sans-serif"
            color: root.fgOnSurfaceVariant
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "DE " + root.germanTime
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.family: "sans-serif"
            color: root.fgOnSurfaceVariant
        }
    }
}

