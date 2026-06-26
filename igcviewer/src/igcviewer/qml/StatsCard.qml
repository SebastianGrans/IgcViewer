import QtQuick

Rectangle {
    id: card

    property string title: ""
    property string value: ""
    property string unit: ""
    property string note: ""

    implicitHeight: col.implicitHeight + 20
    color: "#0f172a"
    radius: 8
    border.color: "#1e293b"
    border.width: 1

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 4

        Text {
            width: parent.width
            text: card.title
            color: "#94a3b8"
            font.pointSize: 9
            elide: Text.ElideRight
        }

        Row {
            spacing: 5
            Text {
                text: card.value
                color: "#f1f5f9"
                font { pointSize: 15; bold: true }
            }
            Text {
                text: card.unit
                color: "#64748b"
                font.pointSize: 10
                anchors.bottom: parent.bottom
                bottomPadding: 2
            }
        }

        Text {
            width: parent.width
            text: card.note
            color: "#64748b"
            font.pointSize: 8
            visible: card.note.length > 0
            elide: Text.ElideRight
        }
    }
}
