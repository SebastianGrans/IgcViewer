import QtQuick

Item {
    id: root

    property var distances: []
    property var altitudes: []
    // cached scale for click → index mapping
    property real _minAlt: 0
    property real _maxDist: 1

    Connections {
        target: FlightBridge
        function onFlightLoaded() {
            var d = JSON.parse(FlightBridge.chartJson);
            root.distances = d.distances;
            root.altitudes = d.altitudes;
            canvas.requestPaint();
        }
        function onHighlightChanged() {
            canvas.requestPaint();
        }
    }

    Connections {
        target: Theme
        function onIsDarkChanged() {
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            var w = width, h = height;
            var pad = 42;
            var plotW = w - 2 * pad;
            var plotH = h - 2 * pad;

            // Background
            ctx.fillStyle = Theme.chartBg.toString();
            ctx.fillRect(0, 0, w, h);

            var alts = root.altitudes;
            var dists = root.distances;
            if (alts.length < 2)
                return;

            // Compute range (avoid spread operator on large arrays)
            var minAlt = alts[0], maxAlt = alts[0];
            for (let i = 1; i < alts.length; i++) {
                if (alts[i] < minAlt)
                    minAlt = alts[i];
                if (alts[i] > maxAlt)
                    maxAlt = alts[i];
            }
            var altRange = Math.max(1, maxAlt - minAlt);
            var maxDist = dists[dists.length - 1];

            // Cache for click handler
            root._minAlt = minAlt;
            root._maxDist = maxDist;

            // Grid lines
            ctx.strokeStyle = Theme.chartGrid.toString();
            ctx.globalAlpha = 0.6;
            ctx.lineWidth = 0.5;
            for (let gi = 0; gi <= 4; gi++) {
                let gy = pad + plotH - gi * plotH / 4;
                ctx.beginPath();
                ctx.moveTo(pad, gy);
                ctx.lineTo(pad + plotW, gy);
                ctx.stroke();
            }

            // Altitude profile line
            ctx.globalAlpha = 1.0;
            ctx.strokeStyle = Theme.chartLine.toString();
            ctx.lineWidth = 2;
            ctx.beginPath();
            for (let pi = 0; pi < alts.length; pi++) {
                let px = pad + (dists[pi] / maxDist) * plotW;
                let py = pad + plotH - ((alts[pi] - minAlt) / altRange) * plotH;
                if (pi === 0)
                    ctx.moveTo(px, py);
                else
                    ctx.lineTo(px, py);
            }
            ctx.stroke();

            // Highlight
            var hi = FlightBridge.highlightedIndex;
            if (hi >= 0 && hi < alts.length) {
                let hx = pad + (dists[hi] / maxDist) * plotW;
                let hy = pad + plotH - ((alts[hi] - minAlt) / altRange) * plotH;

                // Vertical guide line
                ctx.strokeStyle = "rgba(245, 158, 11, 0.5)";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(hx, pad);
                ctx.lineTo(hx, pad + plotH);
                ctx.stroke();

                // Orange dot
                ctx.fillStyle = "#f59e0b";
                ctx.beginPath();
                ctx.arc(hx, hy, 5, 0, 2 * Math.PI);
                ctx.fill();

                // White centre
                ctx.fillStyle = "#ffffff";
                ctx.beginPath();
                ctx.arc(hx, hy, 2.5, 0, 2 * Math.PI);
                ctx.fill();
            }

            // Y-axis labels
            ctx.fillStyle = Theme.chartLabel.toString();
            ctx.font = "10px sans-serif";
            for (let yi = 0; yi <= 4; yi++) {
                let yVal = Math.round(minAlt + yi * altRange / 4);
                let yPos = pad + plotH - yi * plotH / 4;
                ctx.fillText(yVal + "m", 3, yPos + 4);
            }

            // X-axis labels
            for (let xi = 0; xi <= 4; xi++) {
                let xVal = (xi * maxDist / 4).toFixed(1);
                let xPos = pad + xi * plotW / 4;
                ctx.fillText(xVal + "km", xPos - 14, h - 6);
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        function updateHighlight(mouseX) {
            var dists = root.distances;
            if (dists.length < 2)
                return;
            var pad = 42;
            var plotW = root.width - 2 * pad;
            if (mouseX < pad || mouseX > pad + plotW) {
                FlightBridge.setHighlight(-1);
                return;
            }
            var clickDist = ((mouseX - pad) / plotW) * root._maxDist;
            var bestIdx = 0;
            var bestDiff = Math.abs(dists[0] - clickDist);
            for (let i = 1; i < dists.length; i++) {
                let diff = Math.abs(dists[i] - clickDist);
                if (diff < bestDiff) {
                    bestDiff = diff;
                    bestIdx = i;
                }
            }
            FlightBridge.setHighlight(bestIdx);
        }

        onClicked: mouse => updateHighlight(mouse.x)
        onPositionChanged: mouse => updateHighlight(mouse.x)
    }
}
