import QtQuick
import Quickshell

Rectangle {
    id: root

    property string wifiIcon: ""
    property string wifiText: "--"
    property string wxIcon: ""
    property string wxText: "Loading..."
    property string volIcon: ""
    property string volText: "--%"
    property string batIcon: ""
    property string batText: "--%"

    property color surfaceContainer: "#282828"
    property color surfaceVariant: "#504945"
    property color fgOnSurfaceVariant: "#d5c4a1"

    height: 30
    radius: 15
    color: surfaceContainer
    border.color: Qt.rgba(1, 1, 1, 0.08)
    width: statusRow.implicitWidth + 24

    Row {
        id: statusRow
        anchors.centerIn: parent
        spacing: 12

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Image {
                source: root.wifiIcon ? Quickshell.shellPath("svg/wifi/" + root.wifiIcon) : ""
                width: 16
                height: 16
                sourceSize: Qt.size(32, 32)
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
                visible: root.wifiIcon !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifiText
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: "sans-serif"
                color: root.fgOnSurfaceVariant
            }
        }

        Rectangle { width: 1; height: 12; color: root.surfaceVariant; anchors.verticalCenter: parent.verticalCenter }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Image {
                source: root.wxIcon ? Quickshell.shellPath("svg/weather/" + root.wxIcon) : ""
                width: 14
                height: 14
                sourceSize: Qt.size(32, 32)
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
                visible: root.wxIcon !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wxText
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: "sans-serif"
                color: root.fgOnSurfaceVariant
            }
        }

        Rectangle { width: 1; height: 12; color: root.surfaceVariant; anchors.verticalCenter: parent.verticalCenter }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Image {
                source: root.volIcon ? Quickshell.shellPath("svg/volume/" + root.volIcon) : ""
                width: 14
                height: 14
                sourceSize: Qt.size(32, 32)
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
                visible: root.volIcon !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.volText
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: "sans-serif"
                color: root.fgOnSurfaceVariant
            }
        }

        Rectangle { width: 1; height: 12; color: root.surfaceVariant; anchors.verticalCenter: parent.verticalCenter }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Image {
                source: root.batIcon ? Quickshell.shellPath("svg/battery/" + root.batIcon) : ""
                width: 16
                height: 16
                sourceSize: Qt.size(32, 32)
                smooth: true
                anchors.verticalCenter: parent.verticalCenter
                visible: root.batIcon !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batText
                font.pixelSize: 11
                font.weight: Font.Medium
                font.family: "sans-serif"
                color: root.fgOnSurfaceVariant
            }
        }
    }
}

