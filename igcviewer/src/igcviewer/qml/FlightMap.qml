import QtQuick
import QtLocation
import QtPositioning

Item {
    id: root

    property bool maximized: false
    property bool fitted: false
    signal toggleMaximize

    // Placeholder shown before a file is loaded
    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceLow
        radius: 6
        // We defer showing the map until the flight data is loaded and the map
        // has been fitted to the flight track.
        // This prevents briefly showing the map centered around London, before the viewport is
        // adjusted to the flight track.
        visible: !flightMap.visible

        Text {
            anchors.centerIn: parent
            text: "Load an IGC file to see the flight track."
            color: Theme.textMuted
            font.pointSize: 11
        }
    }

    Map {
        id: flightMap
        anchors.fill: parent
        visible: bridge.hasData && root.fitted
        copyrightsVisible: false

        plugin: Plugin {
            name: "osm"
            // Use a single stable tile provider; disable auto-discovery to
            // avoid network calls probing alternative providers at startup.
            PluginParameter {
                name: "osm.mapping.providersrepository.disabled"
                value: "true"
            }
        }

        // Flight track
        MapPolyline {
            line.width: 3
            line.color: "#38bdf8"
            path: bridge.trackCoordinates
        }

        // Start marker (green)
        MapQuickItem {
            coordinate: bridge.startCoordinate
            visible: bridge.hasData
            anchorPoint.x: dot.width / 2
            anchorPoint.y: dot.height / 2
            sourceItem: Rectangle {
                id: dot
                width: 14
                height: 14
                radius: 7
                color: "#10b981"
                border.color: "white"
                border.width: 2
            }
        }

        // End marker (red)
        MapQuickItem {
            coordinate: bridge.endCoordinate
            visible: bridge.hasData
            anchorPoint.x: dotEnd.width / 2
            anchorPoint.y: dotEnd.height / 2
            sourceItem: Rectangle {
                id: dotEnd
                width: 14
                height: 14
                radius: 7
                color: "#ef4444"
                border.color: "white"
                border.width: 2
            }
        }

        // Highlight marker (orange) — synced from altitude chart clicks
        MapQuickItem {
            coordinate: bridge.highlightCoordinate
            visible: bridge.highlightedIndex >= 0
            anchorPoint.x: dotHl.width / 2
            anchorPoint.y: dotHl.height / 2
            sourceItem: Rectangle {
                id: dotHl
                width: 18
                height: 18
                radius: 9
                color: "#fbbf24"
                border.color: "#f59e0b"
                border.width: 2.5
            }
        }

        Timer {
            // NOTE: Without this, there were cases where setting the map bounding box would fail.
            // Sometimes it would only show the world map, other times it would show a small section of the
            // flight path.
            // This delays setting the map bounding box to mitigate that.
            //
            // TODO: Figure out the root cause.
            id: fitTimer
            interval: 40
            repeat: false
            onTriggered: {
                var b = bridge.trackBounds;
                flightMap.fitViewportToGeoShape(b, 20);
                root.fitted = true;
            }
        }

        Connections {
            target: bridge
            function onFlightLoaded() {
                root.fitted = false;
                if (flightMap.mapReady) {
                    fitTimer.restart();
                } else {
                    flightMap.mapReadyChanged.connect(function () {
                        flightMap.mapReadyChanged.disconnect(conn);
                        fitTimer.restart();
                    });
                }
            }
        }
    }

    // Maximize / restore button — floats in the top-right corner of the map
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 8
            rightMargin: 8
        }
        width: 30
        height: 30
        radius: 5
        color: expandHover.containsMouse ? "#2563eb" : "#1d4ed8"
        z: 10

        Text {
            anchors.centerIn: parent
            text: root.maximized ? "⊟" : "⛶"
            color: "#f1f5f9"
            font.pixelSize: 15
        }

        MouseArea {
            id: expandHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMaximize()
        }
    }
}
