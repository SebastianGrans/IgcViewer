import QtQuick
import QtQuick.Window
import QtWebEngine

Window {
    id: cesiumWindow
    width: 1200
    height: 800
    visible: true
    title: "3D Globe"

    WebEngineView {
        id: webView
        anchors.fill: parent
        settings.localContentCanAccessRemoteUrls: true
        url: {
            var params = "?key=" + encodeURIComponent(FlightBridge.maptilerKey);
            if (FlightBridge.hasData) {
                var c = FlightBridge.trackBounds.center;
                params += "&lat=" + c.latitude + "&lon=" + c.longitude;
            }
            return Qt.resolvedUrl("cesium/cesium_view.html") + params;
        }

        onLoadingChanged: function (loadInfo) {
            if (loadInfo.status !== WebEngineView.LoadSucceededStatus || !FlightBridge.hasData)
                return;
            // Decimate before handing to Cesium — a raw multi-thousand-point IGC track
            // is unnecessary geometry detail at globe scale and can be heavy to render
            // on machines without GPU acceleration for WebEngine (software Vulkan/GBM fallback).
            const all = FlightBridge.trackCoordinates;
            const maxPoints = 500;
            const stride = Math.max(1, Math.ceil(all.length / maxPoints));
            const coords = [];
            for (let i = 0; i < all.length; i += stride)
                coords.push([all[i].longitude, all[i].latitude, all[i].altitude]);
            webView.runJavaScript("window.setFlightPath(" + JSON.stringify(coords) + ")");
        }
    }
}
