import QtQuick
import QtGraphs

Item {
    id: root

    property var _distances: []
    property var _altitudes: []

    Connections {
        target: FlightBridge
        function onFlightLoaded() {
            root.loadData();
        }
        function onHighlightChanged() {
            root.updateHighlight();
        }
    }

    ValueAxis {
        id: xAxis
        min: 0
        max: 1
        titleText: qsTr("Distance / km")
        labelFormat: "%.1f"
        gridVisible: false
        subGridVisible: false
        lineVisible: false
    }

    ValueAxis {
        id: yAxis
        min: 0
        max: 1000
        titleText: qsTr("Altitude / m")
        labelFormat: "%.0f"
        gridVisible: true
        subGridVisible: false
        lineVisible: false
    }

    GraphsView {
        id: chartView
        anchors.fill: parent
        axisX: xAxis
        axisY: yAxis

        theme: GraphsTheme {
            theme: GraphsTheme.Theme.UserDefined
            backgroundColor: Theme.chartBg
            plotAreaBackgroundColor: Theme.chartBg
            plotAreaBackgroundVisible: true
            labelTextColor: Theme.chartLabel
            grid.mainColor: Theme.chartGrid
            grid.mainWidth: 0.5
            axisX.mainColor: Theme.chartGrid
            axisX.mainWidth: 0
            axisY.mainColor: Theme.chartGrid
            axisY.mainWidth: 0
        }

        LineSeries {
            id: altitudeSeries
            color: Theme.chartLine
            width: 2
        }

        LineSeries {
            id: highlightLine
            color: "#80f59e0b"
            width: 1
            visible: false
        }

        ScatterSeries {
            id: highlightDot
            visible: false
            pointDelegate: Rectangle {
                width: 10
                height: 10
                radius: 5
                color: "#f59e0b"
                border.color: "#ffffff"
                border.width: 2
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        function findHighlight(mouseX) {
            var dists = root._distances;
            if (dists.length < 2)
                return;
            var pa = chartView.plotArea;
            var clickDist = xAxis.min + (mouseX - pa.x) / pa.width * (xAxis.max - xAxis.min);
            if (clickDist < xAxis.min || clickDist > xAxis.max) {
                FlightBridge.setHighlight(-1);
                return;
            }
            var bestIdx = 0;
            var bestDiff = Math.abs(dists[0] - clickDist);
            for (var i = 1; i < dists.length; i++) {
                var diff = Math.abs(dists[i] - clickDist);
                if (diff < bestDiff) {
                    bestDiff = diff;
                    bestIdx = i;
                }
            }
            FlightBridge.setHighlight(bestIdx);
        }

        onClicked: mouse => findHighlight(mouse.x)
        onPositionChanged: mouse => findHighlight(mouse.x)
    }

    function loadData() {
        var d = JSON.parse(FlightBridge.chartJson);
        root._distances = d.distances;
        root._altitudes = d.altitudes;

        altitudeSeries.clear();
        highlightLine.clear();
        highlightDot.clear();
        highlightLine.visible = false;
        highlightDot.visible = false;

        var alts = root._altitudes;
        var dists = root._distances;
        if (alts.length < 2)
            return;

        var minAlt = alts[0], maxAlt = alts[0];
        for (var i = 1; i < alts.length; i++) {
            if (alts[i] < minAlt)
                minAlt = alts[i];
            if (alts[i] > maxAlt)
                maxAlt = alts[i];
        }
        var pad = Math.max(10, Math.round((maxAlt - minAlt) * 0.05));

        xAxis.min = 0;
        xAxis.max = dists[dists.length - 1];
        yAxis.min = minAlt - pad;
        yAxis.max = maxAlt + pad;

        for (var j = 0; j < dists.length; j++)
            altitudeSeries.append(dists[j], alts[j]);
    }

    function updateHighlight() {
        var hi = FlightBridge.highlightedIndex;
        if (hi < 0 || root._distances.length === 0) {
            highlightDot.visible = false;
            highlightLine.visible = false;
            return;
        }
        var hx = root._distances[hi];
        var hy = root._altitudes[hi];

        highlightLine.clear();
        highlightLine.append(hx, yAxis.min);
        highlightLine.append(hx, yAxis.max);
        highlightLine.visible = true;

        highlightDot.clear();
        highlightDot.append(hx, hy);
        highlightDot.visible = true;
    }
}
