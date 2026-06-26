import QtQuick

Rectangle {
    id: card

    property string title: ""
    property string value: ""
    property string unit: ""
    property string note: ""

    implicitHeight: col.implicitHeight + 20
    color: Theme.surfaceLow
    radius: 8
    border.color: Theme.divider
    border.width: 1

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 4

        Text {
            width: parent.width
            text: card.title
            color: Theme.textSecondary
            font.pointSize: Theme.fontSm
            elide: Text.ElideRight
        }

        Row {
            spacing: 5
            Text {
                text: card.value
                color: Theme.textPrimary
                font { pointSize: Theme.fontXl; bold: true }
            }
            Text {
                text: card.unit
                color: Theme.textMuted
                font.pointSize: Theme.fontMd
                anchors.bottom: parent.bottom
                bottomPadding: 2
            }
        }

        Text {
            width: parent.width
            text: card.note.length > 0 ? card.note : " "
            color: "#64748b"
            font.pointSize: Theme.fontXs
            opacity: card.note.length > 0 ? 1 : 0
            elide: Text.ElideRight
        }
    }
}
