import QtQuick

// Vertical workspace indicator matching the clock and tray capsules.
// Focused: tall bright pill carrying the number. Occupied: dark capsule.
// Empty: slightly shorter, dimmer capsule. Only the focused one shows a number.
Item {
    id: root

    property var workspaces: []
    property int wsSlots: 5

    property color surfaceVariant: "#504945"
    property color surfaceDim: "#32302f"
    property color fgOnSurfaceVariant: "#d5c4a1"
    property color primaryColor: "#fabd2f"
    property color fgOnPrimary: "#1d2021"
    property color errorColor: "#fb4934"
    property color fgOnError: "#1d2021"
    property color trackColor: "#3c3836"

    implicitWidth: 48
    implicitHeight: track.height + 32

    Rectangle {
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 16
        width: 38
        height: wsCol.implicitHeight + 24
        radius: width / 2
        color: root.trackColor

        Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Column {
            id: wsCol
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: root.wsSlots

                Rectangle {
                    id: pill
                    readonly property var ws: root.workspaces.find(w => w.num === index + 1) || null
                    readonly property bool occupied: ws !== null && ws.visible !== false
                    readonly property bool focused: ws ? Boolean(ws.focused) : false
                    readonly property bool urgent: ws ? Boolean(ws.urgent) : false

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 28
                    height: focused ? 48 : (occupied ? 26 : 20)
                    radius: width / 2

                    color: {
                        if (urgent) return root.errorColor
                        if (focused) return root.primaryColor
                        return occupied ? "#665c54" : Qt.rgba(0x66/255, 0x5c/255, 0x54/255, .55)
                    }

                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 180 } }

                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        visible: opacity > 0
                        opacity: pill.focused ? 1 : 0
                        font.pixelSize: 17
                        font.weight: Font.Black
                        font.family: "sans-serif"
                        color: pill.urgent ? root.fgOnError : root.fgOnPrimary
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                    }
                }
            }
        }
    }
}
