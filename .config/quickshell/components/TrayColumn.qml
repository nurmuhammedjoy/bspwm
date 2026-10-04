import QtQuick
import Quickshell

// Bottom cluster. One shared container holds the status icons as loose
// glyphs, battery with its percentage pinned at the bottom. Two round
// buttons sit below the container.
Item {
    id: root

    property string wifiIcon: ""
    property string wxIcon: ""
    property string volIcon: ""
    property string batIcon: ""
    property string batText: "--%"

    property color groupColor: "#3c3836"
    property color fgOnSurfaceVariant: "#d5c4a1"
    property color accentGreen: "#b8bb26"
    property color accentYellow: "#fabd2f"
    property color accentRed: "#fb4934"

    signal launcherClicked()
    signal powerClicked()

    implicitWidth: 48
    implicitHeight: trayCol.implicitHeight + 28

    Column {
        id: trayCol
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        spacing: 14

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 38
            height: iconCol.implicitHeight + 28
            radius: 19
            color: root.groupColor

            Column {
                id: iconCol
                anchors.centerIn: parent
                spacing: 17

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 22; height: 22
                    sourceSize: Qt.size(43, 43)
                    smooth: true
                    visible: root.wifiIcon !== ""
                    source: root.wifiIcon ? Quickshell.shellPath("svg/wifi/" + root.wifiIcon) : ""
                }

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 20; height: 20
                    sourceSize: Qt.size(41, 41)
                    smooth: true
                    visible: root.wxIcon !== ""
                    source: root.wxIcon ? Quickshell.shellPath("svg/weather/" + root.wxIcon) : ""
                }

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 19; height: 19
                    sourceSize: Qt.size(38, 38)
                    smooth: true
                    visible: root.volIcon !== ""
                    source: root.volIcon ? Quickshell.shellPath("svg/volume/" + root.volIcon) : ""
                }

                // Battery: icon plus percentage.
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 2

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 25; height: 25
                        sourceSize: Qt.size(50, 50)
                        smooth: true
                        visible: root.batIcon !== ""
                        source: root.batIcon ? Quickshell.shellPath("svg/battery/" + root.batIcon) : ""
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.batText.replace("%", "")
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.family: "sans-serif"
                        color: root.accentGreen
                    }
                }
            }
        }

        // Launcher button (placeholder): 2x2 grid glyph.
        Rectangle {
            id: launcher
            anchors.horizontalCenter: parent.horizontalCenter
            width: 38; height: 38; radius: 19
            color: Qt.rgba(root.accentYellow.r, root.accentYellow.g, root.accentYellow.b, launcherArea.containsMouse ? 0.30 : 0.16)
            Behavior on color { ColorAnimation { duration: 120 } }

            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: 4
                Repeater {
                    model: 4
                    Rectangle { width: 7; height: 7; radius: 3; color: root.accentYellow }
                }
            }

            MouseArea {
                id: launcherArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launcherClicked()
            }
        }

        // Power button (placeholder): ring with a gap and a stem.
        Rectangle {
            id: power
            anchors.horizontalCenter: parent.horizontalCenter
            width: 38; height: 38; radius: 19
            color: Qt.rgba(root.accentRed.r, root.accentRed.g, root.accentRed.b, powerArea.containsMouse ? 0.30 : 0.16)
            Behavior on color { ColorAnimation { duration: 120 } }

            Canvas {
                anchors.centerIn: parent
                width: 18; height: 18
                property color stroke: root.accentRed
                onStrokeChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = stroke
                    ctx.lineWidth = 2.2
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.arc(9, 9.8, 6.8, -Math.PI * 0.30, Math.PI * 1.30 + Math.PI * 0.0, false)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(9, 1.6)
                    ctx.lineTo(9, 8.6)
                    ctx.stroke()
                }
            }

            MouseArea {
                id: powerArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.powerClicked()
            }
        }
    }
}
