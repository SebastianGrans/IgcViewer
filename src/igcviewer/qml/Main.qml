import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: true
    property bool mapMaximized: false
    property bool statsCollapsed: false
    width: 980
    height: 860
    minimumWidth: 700
    minimumHeight: 600
    title: "✈️ IGC Flight Viewer"
    color: Theme.windowBg

    FileDialog {
        id: fileDialog
        nameFilters: ["IGC files (*.igc *.IGC)", "All files (*)"]
        onAccepted: FlightBridge.loadFile(selectedFile.toString())
    }

    DropArea {
        anchors.fill: parent
        onDropped: function (drop) {
            if (drop.hasUrls)
                FlightBridge.loadFile(drop.urls[0].toString());
        }
    }

    Connections {
        target: FlightBridge
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
        color: Theme.errorBg
        border.color: Theme.errorBorder
        border.width: 1
        z: 10
        Text {
            id: errorText
            anchors.centerIn: parent
            color: Theme.errorText
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
            //Layout.topMargin: FlightBridge.hasData ? 8 : 0
            implicitHeight: FlightBridge.hasData ? 1 : 0
            color: Theme.divider
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
                id: loadBtn
                text: "📁  Load IGC File"
                onClicked: fileDialog.open()
                background: Rectangle {
                    color: loadBtn.pressed ? "#1e3a5f" : (loadBtn.hovered ? "#1e40af" : "#1d4ed8")
                    radius: 6
                }
                contentItem: Text {
                    text: loadBtn.text
                    color: "#f1f5f9"
                    font.pointSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                Layout.fillWidth: true
                text: FlightBridge.statusText
                color: FlightBridge.hasData ? Theme.textSuccess : Theme.textMuted
                font.pointSize: 10
                elide: Text.ElideRight
            }
            Rectangle {
                implicitHeight: 26
                implicitWidth: 84
                radius: 5
                clip: true
                border.color: Theme.divider
                border.width: 1
                color: Theme.surfaceLow

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: [
                            {
                                icon: "☀",
                                mode: "light"
                            },
                            {
                                icon: "⊙",
                                mode: "system"
                            },
                            {
                                icon: "☾",
                                mode: "dark"
                            }
                        ]

                        delegate: Rectangle {
                            id: modeDelegate
                            required property var modelData
                            required property int index
                            implicitWidth: 28
                            implicitHeight: 26
                            color: Theme.mode === modeDelegate.modelData.mode ? "#1d4ed8" : (modeArea.containsMouse ? Theme.divider : "transparent")

                            Rectangle {
                                visible: modeDelegate.index > 0
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                }
                                width: 1
                                color: Theme.divider
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modeDelegate.modelData.icon
                                color: Theme.mode === modeDelegate.modelData.mode ? "#f1f5f9" : Theme.textMuted
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: modeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Theme.mode = modeDelegate.modelData.mode
                            }
                        }
                    }
                }
            }
        }

        // Divider with collapse toggle
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 6
            visible: !root.mapMaximized
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.divider
            }

            Text {
                text: "flight metrics"
                color: Theme.textMuted
                font.pointSize: 8
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
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.preferredHeight: root.statsCollapsed ? 0 : statsGrid.implicitHeight + (FlightBridge.hasData ? 8 : 0)
            clip: true
            visible: !root.mapMaximized && FlightBridge.hasData

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

        // altitude chart
        AltitudeChart {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            Layout.topMargin: 10
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 10
            visible: !root.mapMaximized
        }
    }
}
