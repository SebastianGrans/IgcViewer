import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool mapMaximized: false
    property bool statsCollapsed: false

    spacing: 6
    visible: !root.mapMaximized

    // Divider with collapse toggle
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.divider
        }

        Text {
            text: "flight metrics"
            color: Theme.textMuted
            font.pointSize: Theme.fontXs
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.divider
        }

        Text {
            text: "⌞ ⌝"
            color: Theme.textMuted
            font.pixelSize: 11
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.statsCollapsed = !root.statsCollapsed
            }
        }
    }

    // Collapsible stats cards
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.statsCollapsed ? 0 : statsGrid.implicitHeight + (FlightBridge.hasData ? 8 : 0)
        clip: true
        visible: FlightBridge.hasData

        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        GridLayout {
            id: statsGrid
            width: parent.width
            y: 8
            columns: 4
            columnSpacing: 8
            rowSpacing: 8
            Repeater {
                model: FlightBridge.hasData ? JSON.parse(FlightBridge.statsJson) : []
                delegate: StatsCard {
                    required property var modelData
                    Layout.fillWidth: true
                    title: modelData.title
                    value: modelData.value
                    unit: modelData.unit
                    note: modelData.note
                }
            }
        }
    }
}
