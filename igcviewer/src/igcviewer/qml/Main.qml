import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: true
    property bool mapMaximized: false
    width: 980
    height: 860
    minimumWidth: 700
    minimumHeight: 600
    title: "✈️ IGC Flight Viewer"
    color: "#0a0e17"

    FileDialog {
        id: fileDialog
        nameFilters: ["IGC files (*.igc *.IGC)", "All files (*)"]
        onAccepted: bridge.loadFile(selectedFile.toString())
    }

    DropArea {
        anchors.fill: parent
        onDropped: function (drop) {
            if (drop.hasUrls)
                bridge.loadFile(drop.urls[0].toString());
        }
    }

    Connections {
        target: bridge
        function onFlightError(msg) {
            errorText.text = "⚠️ " + msg;
            errorBar.visible = true;
            errorTimer.restart();
        }
    }
    Rectangle {
        id: errorBar
        visible: false
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 16
        }
        width: errorText.implicitWidth + 32
        height: 36
        radius: 6
        color: "#7f1d1d"
        border.color: "#ef4444"
        border.width: 1
        z: 10
        Text {
            id: errorText
            anchors.centerIn: parent
            color: "#fca5a5"
            font.pointSize: 10
        }
        Timer {
            id: errorTimer
            interval: 4000
            onTriggered: errorBar.visible = false
        }
    }

    // No ScrollView — it steals scroll/drag events and breaks Map pan & zoom.
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            //Layout.topMargin: bridge.hasData ? 8 : 0
            height: bridge.hasData ? 1 : 0
            color: "#1e293b"
            visible: !root.mapMaximized
        }

        // map — grows to fill all remaining space
        FlightMap {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            maximized: root.mapMaximized
            onToggleMaximize: root.mapMaximized = !root.mapMaximized
        }

        // top bar
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 8
            spacing: 10
            visible: !root.mapMaximized
            Button {
                text: "📁  Load IGC File"
                onClicked: fileDialog.open()
                background: Rectangle {
                    color: parent.pressed ? "#1e3a5f" : (parent.hovered ? "#1e40af" : "#1d4ed8")
                    radius: 6
                }
                contentItem: Text {
                    text: parent.text
                    color: "#f1f5f9"
                    font.pointSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                Layout.fillWidth: true
                text: bridge.statusText
                color: bridge.hasData ? "#86efac" : "#64748b"
                font.pointSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 6
            height: 1
            color: "#1e293b"
            visible: !root.mapMaximized
        }

        // stats cards
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: bridge.hasData ? 8 : 0
            visible: bridge.hasData && !root.mapMaximized
            columns: 3
            columnSpacing: 8
            rowSpacing: 8
            Repeater {
                model: bridge.hasData ? JSON.parse(bridge.statsJson) : []
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

        // altitude chart — fixed height at bottom
        AltitudeChart {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 10
            visible: !root.mapMaximized
        }
    }
}
