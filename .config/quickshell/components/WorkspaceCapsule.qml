import QtQuick

Rectangle {
    id: root

    property var workspaces: []
    property int wsSlots: 5

    property color surfaceContainer: "#282828"
    property color surfaceVariant: "#504945"
    property color fgOnSurfaceVariant: "#d5c4a1"
    property color primaryColor: "#fabd2f"
    property color fgOnPrimary: "#1d2021"
    property color errorColor: "#fb4934"
    property color fgOnError: "#1d2021"

    height: 30
    radius: 15
    color: surfaceContainer
    border.color: Qt.rgba(1, 1, 1, 0.08)
    width: wsRow.implicitWidth + 18

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.wsSlots

            Rectangle {
                id: pill
                readonly property var ws: root.workspaces.find(w => w.num === index + 1) || null
                readonly property bool occupied: ws !== null && ws.visible !== false
                readonly property bool focused: ws ? Boolean(ws.focused) : false
                readonly property bool urgent: ws ? Boolean(ws.urgent) : false
                readonly property bool hasCustomName: ws ? (ws.name !== undefined && String(ws.name) !== String(ws.num)) : false

                anchors.verticalCenter: parent.verticalCenter
                height: 18
                radius: 9

                width: {
                    if (focused) {
                        return hasCustomName ? wsContentRow.implicitWidth + 16 : 34
                    } else if (occupied) {
                        return 18
                    } else {
                        return 12
                    }
                }

                color: {
                    if (urgent) return root.errorColor
                    if (focused) return root.primaryColor
                    if (occupied) return root.surfaceVariant
                    return Qt.rgba(root.fgOnSurfaceVariant.r, root.fgOnSurfaceVariant.g, root.fgOnSurfaceVariant.b, 0.25)
                }

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: wsContentRow
                    anchors.centerIn: parent
                    spacing: 4
                    opacity: (occupied || focused) ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: index + 1
                        font.pixelSize: 11
                        font.weight: focused ? Font.Bold : Font.Medium
                        font.family: "sans-serif"
                        color: {
                            if (urgent) return root.fgOnError
                            if (focused) return root.fgOnPrimary
                            return root.fgOnSurfaceVariant
                        }
                    }

                    Text {
                        id: wsLabel
                        visible: focused && hasCustomName
                        anchors.verticalCenter: parent.verticalCenter
                        text: (ws && ws.name) ? ws.name : ""
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: "sans-serif"
                        color: root.fgOnPrimary
                    }
                }
            }
        }
    }
}

