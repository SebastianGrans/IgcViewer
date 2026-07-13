import QtQuick
import QtLocation
import QtPositioning

Item {
    id: root

    property bool maximized: false
    property bool fitted: false
    property bool satelliteMode: false
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
        visible: !flightMapView.visible

        Text {
            anchors.centerIn: parent
            text: "Load an IGC file to see the flight track."
            color: Theme.textMuted
            font.pointSize: Theme.fontLg
        }
    }

    MapView {
        id: flightMapView
        anchors.fill: parent
        visible: FlightBridge.hasData && root.fitted
        map.copyrightsVisible: false
        map.plugin: Plugin {
            name: "osm"
            // Use a single stable tile provider; disable auto-discovery to
            // avoid network calls probing alternative providers at startup.
            PluginParameter {
                name: "osm.mapping.providersrepository.disabled"
                value: "true"
            }
            PluginParameter {
                name: "osm.mapping.custom.host"
                value: "https://api.maptiler.com/tiles/satellite-v2/%z/%x/%y.png?key=" + FlightBridge.maptilerKey
            }
        }
    }

    // Map items are declared here and added to the inner map via addMapItem(),
    // because MapView does not forward declarative children to its inner Map.
    MapPolyline {
        id: trackPolyline
        line.width: 3
        line.color: "#38bdf8"
        path: FlightBridge.trackCoordinates
    }

    // Start marker (green)
    MapQuickItem {
        id: startMarker
        coordinate: FlightBridge.startCoordinate
        visible: FlightBridge.hasData
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
        id: endMarker
        coordinate: FlightBridge.endCoordinate
        visible: FlightBridge.hasData
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
        id: highlightMarker
        coordinate: FlightBridge.highlightCoordinate
        visible: FlightBridge.highlightedIndex >= 0
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

    Component {
        id: cesiumWindowComponent
        CesiumWindow {}
    }

    function openCesiumWindow() {
        cesiumWindowComponent.createObject(root);
    }

    function applyMapType() {
        if (!flightMapView.map.mapReady)
            return;
        const types = flightMapView.map.supportedMapTypes;
        for (let i = 0; i < types.length; i++) {
            const isCustom = types[i].style === MapType.CustomMap;
            if (root.satelliteMode === isCustom) {
                flightMapView.map.activeMapType = types[i];
                return;
            }
        }
    }

    onSatelliteModeChanged: applyMapType()

    Component.onCompleted: {
        flightMapView.map.addMapItem(trackPolyline);
        flightMapView.map.addMapItem(startMarker);
        flightMapView.map.addMapItem(endMarker);
        flightMapView.map.addMapItem(highlightMarker);
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
            var b = FlightBridge.trackBounds;
            flightMapView.map.fitViewportToGeoShape(b, 20);
            root.fitted = true;
            root.applyMapType();
        }
    }

    Connections {
        target: FlightBridge
        function onFlightLoaded() {
            root.fitted = false;
            if (flightMapView.map.mapReady) {
                fitTimer.restart();
            } else {
                let onReady = function () {
                    flightMapView.map.mapReadyChanged.disconnect(onReady);
                    fitTimer.restart();
                };
                flightMapView.map.mapReadyChanged.connect(onReady);
            }
        }
    }

    // Open 3D Cesium globe in a separate window
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 8
            rightMargin: 122
        }
        width: 30
        height: 30
        radius: 5
        visible: FlightBridge.hasData && FlightBridge.maptilerKey !== ""
        color: cesiumHover.containsMouse ? "#2563eb" : "#1d4ed8"
        z: 10

        Text {
            anchors.centerIn: parent
            text: "3D"
            color: "#f1f5f9"
            font.pixelSize: 10
        }

        MouseArea {
            id: cesiumHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openCesiumWindow()
        }
    }

    // Satellite toggle button — switches between street map and Maptiler satellite imagery
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 8
            rightMargin: 84
        }
        width: 30
        height: 30
        radius: 5
        visible: FlightBridge.hasData && FlightBridge.maptilerKey !== ""
        color: root.satelliteMode ? "#0369a1" : (satHover.containsMouse ? "#2563eb" : "#1d4ed8")
        z: 10

        Text {
            anchors.centerIn: parent
            text: "Sat"
            color: "#f1f5f9"
            font.pixelSize: 10
        }

        MouseArea {
            id: satHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.satelliteMode = !root.satelliteMode
        }
    }

    // Fit-to-track button — snaps viewport back to the flight path
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 8
            rightMargin: 46
        }
        width: 30
        height: 30
        radius: 5
        visible: FlightBridge.hasData
        color: fitHover.containsMouse ? "#2563eb" : "#1d4ed8"
        z: 10

        Text {
            anchors.centerIn: parent
            text: "⊙"
            color: "#f1f5f9"
            font.pixelSize: 15
        }

        MouseArea {
            id: fitHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: flightMapView.map.fitViewportToGeoShape(FlightBridge.trackBounds, 20)
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

    // Maptiler attribution — required by the free tier when satellite tiles are active
    Rectangle {
        visible: root.satelliteMode
        anchors {
            bottom: parent.bottom
            left: parent.left
            bottomMargin: 4
            leftMargin: 4
        }
        z: 10
        color: "#ccffffff"
        radius: 3
        width: attributionRow.width + 8
        height: attributionRow.height + 6

        Row {
            id: attributionRow
            anchors.centerIn: parent
            spacing: 6

            Image {
                source: "https://api.maptiler.com/resources/logo.svg"
                height: 16
                fillMode: Image.PreserveAspectFit
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://www.maptiler.com/")
                }
            }

            Text {
                text: "© MapTiler"
                font.pixelSize: 11
                color: "#333"
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://maptiler.com/copyright")
                }
            }

            Text {
                text: "© OpenStreetMap contributors"
                font.pixelSize: 11
                color: "#333"
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://www.openstreetmap.org/copyright")
                }
            }
        }
    }
}
