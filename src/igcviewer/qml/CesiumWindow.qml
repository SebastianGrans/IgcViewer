import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtWebEngine

Window {
    id: cesiumWindow
    width: 1200
    height: 800
    visible: true
    title: "3D Globe"
    color: Theme.windowBg

    property bool pageReady: false

    function syncHighlight() {
        if (!pageReady)
            return;
        if (FlightBridge.highlightedIndex >= 0) {
            var c = FlightBridge.highlightCoordinate;
            webView.runJavaScript(`window.setHighlight(${c.longitude},${c.latitude},${c.altitude})`);
        } else {
            webView.runJavaScript("window.clearHighlight()");
        }
    }

    Connections {
        target: FlightBridge
        function onHighlightChanged() {
            cesiumWindow.syncHighlight();
        }
    }

    WebEngineView {
        id: webView
        anchors.fill: parent
        settings.localContentCanAccessRemoteUrls: true
        backgroundColor: Theme.windowBg
        url: {
            var params = `?key=${encodeURIComponent(FlightBridge.maptilerKey)}`;
            if (FlightBridge.hasData) {
                let c = FlightBridge.trackBounds.center;
                params += `&lat=${c.latitude}&lon=${c.longitude}`;
            }
            return Qt.resolvedUrl("cesium/cesium_view.html") + params;
        }

        onLoadingChanged: function (loadInfo) {
            if (loadInfo.status !== WebEngineView.LoadSucceededStatus || !FlightBridge.hasData)
                return;
            // Decimate before handing to Cesium — a raw multi-thousand-point IGC track
            // is unnecessary geometry detail at globe scale and can be heavy to render
            // on machines without GPU acceleration for WebEngine (software Vulkan/GBM fallback).
            // FIXME: I have no idea if this is actually needed. It was 500 at first, but then I
            // changed it to 2000 without any issues.
            const all = FlightBridge.trackCoordinates;
            const maxPoints = 2000;
            const stride = Math.max(1, Math.ceil(all.length / maxPoints));
            const coords = [];
            for (let i = 0; i < all.length; i += stride)
                coords.push([all[i].longitude, all[i].latitude, all[i].altitude]);
            webView.runJavaScript(`window.setFlightPath(${JSON.stringify(coords)})`);
            var s = FlightBridge.startCoordinate;
            var e = FlightBridge.endCoordinate;
            webView.runJavaScript(`window.setEndpoints(${s.longitude},${s.latitude},${s.altitude},${e.longitude},${e.latitude},${e.altitude})`);

            cesiumWindow.setTrackAlpha(trackAlphaSlider.value);
            cesiumWindow.pageReady = true;
            cesiumWindow.syncHighlight();
        }
    }

    function setTrackAlpha(alpha) {
        if (cesiumWindow.pageReady)
            webView.runJavaScript(`window.setTrackAlpha(${alpha})`);
    }

    ColumnLayout {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 8
            rightMargin: 8
        }
        spacing: 8
        z: 10

        MapButton {
            visible: FlightBridge.hasData
            label: "⊙"
            labelPixelSize: 15
            Layout.alignment: Qt.AlignRight
            onClicked: webView.runJavaScript("window.resetView()")
        }

        FancySlider {
            id: trackAlphaSlider
            Layout.alignment: Qt.AlignRight
            label: "◑"
            from: 0.0
            value: 0.80 // NOTE: This needs to match the default alpha in cesium_view.html
            to: 0.99 // NOTE: We set the max to 0.99, because otherwise the track blinks when it hits 1.0
            onValueChanged: cesiumWindow.setTrackAlpha(value)
        }
    }
}
