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
    title: "🪂 IGC Flight Viewer"
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

    Shortcut {
        sequences: [StandardKey.Quit]
        context: Qt.ApplicationShortcut

        onActivated: Qt.quit()
    }

    Shortcut {
        sequences: [StandardKey.ZoomIn]
        context: Qt.ApplicationShortcut
        onActivated: Theme.fontScale = Math.min(2.0, Theme.fontScale + 0.1)
    }
    Shortcut {
        sequences: [StandardKey.ZoomOut]
        context: Qt.ApplicationShortcut
        onActivated: Theme.fontScale = Math.max(0.5, Theme.fontScale - 0.1)
    }
    Shortcut {
        sequence: "Ctrl+0"
        context: Qt.ApplicationShortcut
        onActivated: Theme.fontScale = 1.0
    }

    Shortcut {
        sequence: "3"
        context: Qt.ApplicationShortcut
        onActivated: flightMap.openCesiumWindow()
    }

    function openCesiumWindow() {
        flightMap.openCesiumWindow();
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
            font.pointSize: Theme.fontMd
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
        spacing: 10

        // map — grows to fill all remaining space
        FlightMap {
            id: flightMap
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 8
            maximized: root.mapMaximized
            onToggleMaximize: root.mapMaximized = !root.mapMaximized
        }

        // top bar
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
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
                    font.pointSize: Theme.fontMd
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                Layout.fillWidth: true
                text: FlightBridge.statusText
                color: FlightBridge.hasData ? Theme.textSuccess : Theme.textMuted
                font.pointSize: Theme.fontMd
                elide: Text.ElideRight
            }
            Rectangle {
                implicitHeight: 26
                implicitWidth: 84
                radius: 5
                border.color: Theme.divider
                border.width: 1
                color: Theme.surfaceLow

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: [
                            {
                                icon: "☀",
                                mode: Theme.Mode.Light,
                                label: "Light"
                            },
                            {
                                icon: "⊙",
                                mode: Theme.Mode.System,
                                label: "Follow system"
                            },
                            {
                                icon: "☾",
                                mode: Theme.Mode.Dark,
                                label: "Dark"
                            }
                        ]

                        delegate: Rectangle {
                            id: modeDelegate
                            required property var modelData
                            required property int index
                            implicitWidth: 28
                            implicitHeight: 26
                            color: Theme.mode === modeDelegate.modelData.mode ? "#1d4ed8" : (modeArea.containsMouse ? Theme.divider : "transparent")

                            // Rounded corners for the first and last buttons
                            topLeftRadius: modeDelegate.index === 0 ? 5 : 0
                            bottomLeftRadius: modeDelegate.index === 0 ? 5 : 0
                            topRightRadius: modeDelegate.index === 2 ? 5 : 0
                            bottomRightRadius: modeDelegate.index === 2 ? 5 : 0

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

                                AppToolTip {
                                    visible: modeArea.containsMouse
                                    text: qsTr(modeDelegate.modelData.label)
                                }
                            }
                        }
                    }
                }
            }
        }

        StatsPanel {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            mapMaximized: root.mapMaximized
        }

        // altitude chart
        AltitudeChart {
            Layout.fillWidth: true
            Layout.preferredHeight: 250
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 8
            visible: !root.mapMaximized
        }
    }
}
