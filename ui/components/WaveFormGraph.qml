import QtQuick 2.15
import QtQuick.Controls.Material 6.8
import "../utils"

Item {
    id: root
    width: 300
    height: 150

    property var waveData: []
    property var cuePoints: []
    property bool independentScale: false
    property var datasetColors: []
    property var cueNLabels: []
    property double lineWidth: 2.5
    property bool showCueLabels: true

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            if (!root.waveData || root.waveData.length === 0) {
                return;
            }

            // Normalize data to array of arrays
            var datasets = [];
            if (Array.isArray(root.waveData)) {
                datasets = root.waveData;
            } else {
                datasets = [root.waveData];
            }

            if (datasets.length === 0 || datasets[0].length < 2) {
                return;
            }

            // Find global min/max for scaling (and per-dataset Y ranges for independent scaling)
            var minX = datasets[0][0].x;
            var maxX = datasets[0][datasets[0].length - 1].x;
            var minY = datasets[0][0].y;
            var maxY = datasets[0][0].y;

            // Arrays to hold per-dataset Y ranges when independent scaling is enabled
            var perMinY = [];
            var perMaxY = [];

            for (var d = 0; d < datasets.length; d++) {
                var data = datasets[d];
                if (data.length > 0) {
                    if (data[0].x < minX)
                        minX = data[0].x;
                    if (data[data.length - 1].x > maxX)
                        maxX = data[data.length - 1].x;

                    var dMin = data[0].y;
                    var dMax = data[0].y;

                    for (var i = 0; i < data.length; i++) {
                        var y = data[i].y;
                        if (y < minY)
                            minY = y;
                        if (y > maxY)
                            maxY = y;
                        if (y < dMin)
                            dMin = y;
                        if (y > dMax)
                            dMax = y;
                    }

                    dMin = dMin - (dMax - dMin) * 0.01;
                    dMax = dMax + (dMax - dMin) * 0.01;

                    perMinY.push(dMin);
                    perMaxY.push(dMax);
                } else {
                    // Keep placeholder values for empty datasets
                    perMinY.push(0);
                    perMaxY.push(0);
                }
            }
            
            minY = minY - (maxY - minY) * 0.01;
            maxY = maxY + (maxY - minY) * 0.01;

            Logger.debug("MinX: " + minX);
            Logger.debug("MaxX: " + maxX);
            Logger.debug("MinY: " + minY);
            Logger.debug("MaxY: " + maxY);

            // Add some padding
            var rangeY = maxY - minY;
            if (rangeY === 0) {
                rangeY = 1.0;
            }

            var rangeX = maxX - minX;
            if (rangeX === 0) {
                rangeX = 1.0;
            }

            // Reserve space for Y axis and paddings
            var leftMargin = 40;
            var topPadding = 10;
            var bottomPadding = (root.cueNLabels && root.cueNLabels.length > 0) ? 40 : 20;
            var graphWidth = canvas.width - leftMargin;
            var graphHeight = canvas.height - topPadding - bottomPadding;

            function scaleX(x) {
                let scaledX = (x - minX) / rangeX * graphWidth;
                if (scaledX < 0)
                    return leftMargin;
                if (scaledX > graphWidth)
                    return leftMargin + graphWidth;
                return scaledX + leftMargin;
            }

            function scaleY(y, datasetIndex) {
                // If independentScale is enabled and a datasetIndex is provided,
                // scale using that dataset's min/max Y range; otherwise use global range.
                var min = minY;
                var range = rangeY;
                if (root.independentScale && typeof datasetIndex === "number" && perMinY.length > datasetIndex) {
                    min = perMinY[datasetIndex];
                    var max = perMaxY[datasetIndex];
                    range = max - min;
                    if (range === 0)
                        range = 1.0;
                }
                // Y is inverted in canvas, so we subtract from height
                let scaledY = (y - min) / range * graphHeight;
                if (scaledY < 0)
                    return graphHeight + topPadding;
                if (scaledY > graphHeight)
                    return topPadding;
                return graphHeight + topPadding - scaledY;
            }

            // Draw Y axis
            ctx.strokeStyle = Theme.outline(Material.theme);
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(leftMargin, topPadding);
            ctx.lineTo(leftMargin, canvas.height - bottomPadding);
            ctx.stroke();

            // Draw Y axis marks
            ctx.beginPath();
            ctx.moveTo(leftMargin, topPadding);
            ctx.lineTo(leftMargin - 5, topPadding);
            ctx.moveTo(leftMargin, canvas.height - bottomPadding);
            ctx.lineTo(leftMargin - 5, canvas.height - bottomPadding);
            ctx.stroke();

            // Draw Y axis labels
            ctx.fillStyle = Theme.onSurfaceVariant(Material.theme);
            ctx.font = "10px sans-serif";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillText(maxY.toFixed(2), leftMargin - 8, topPadding);
            ctx.fillText(minY.toFixed(2), leftMargin - 8, canvas.height - bottomPadding);

            // Draw cue points
            ctx.lineWidth = 1;
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            // Draw 0 mark and line
            if (minY <= 0 && maxY >= 0) {
                var y0 = scaleY(0);

                // Draw horizontal line
                ctx.save();
                ctx.beginPath();
                ctx.rect(leftMargin, topPadding, graphWidth, graphHeight);
                ctx.clip();

                ctx.beginPath();
                ctx.moveTo(leftMargin, y0);
                ctx.lineTo(leftMargin + graphWidth, y0);
                ctx.strokeStyle = Theme.outlineVariant(Material.theme);
                ctx.lineWidth = 1;
                ctx.stroke();
                ctx.restore();

                // Draw axis mark
                ctx.beginPath();
                ctx.moveTo(leftMargin, y0);
                ctx.lineTo(leftMargin - 5, y0);
                ctx.strokeStyle = Theme.outline(Material.theme);
                ctx.lineWidth = 1;
                ctx.stroke();

                // Draw label
                ctx.fillStyle = Theme.onSurfaceVariant(Material.theme);
                ctx.textAlign = "right";
                ctx.fillText("0", leftMargin - 8, y0);
            }

            var nIdx = 0;
            for (var i = 0; i < root.cuePoints.length; i++) {
                var cue = root.cuePoints[i];
                var x = scaleX(cue.position);
                var width = scaleX(cue.position + cue.length) - x;

                if (cue.label.toUpperCase().startsWith("P")) {
                    ctx.fillStyle = Qt.alpha(Theme.harmonize("#FFC107", Material.theme), 0.5);
                    ctx.strokeStyle = Theme.outline(Material.theme);
                } else if (cue.label.toUpperCase().startsWith("N")) {
                    ctx.fillStyle = Qt.alpha(Theme.harmonize("#4CAF50", Material.theme), 0.5);
                    ctx.strokeStyle = Theme.outline(Material.theme);
                } else if (cue.label.toUpperCase().startsWith("T")) {
                    ctx.fillStyle = Qt.alpha(Theme.harmonize("#FF9800", Material.theme), 0.5);
                    ctx.strokeStyle = Theme.outline(Material.theme);
                } else {
                    ctx.fillStyle = Qt.alpha(Theme.harmonize("#FFFFFF", Material.theme), 0.1);
                    ctx.strokeStyle = Theme.outline(Material.theme);
                }

                // Draw rectangle
                ctx.beginPath();
                ctx.rect(x, topPadding, width, graphHeight);
                ctx.fill();
                ctx.stroke();

                // Draw label
                if (root.showCueLabels || root.cueNLabels.length > 0) {
                    ctx.fillStyle = Theme.onSurface(Material.theme);
                    ctx.font = "10px sans-serif";
                    var labelY = canvas.height - bottomPadding + 15;
                    if (root.showCueLabels)
                        ctx.fillText(cue.label, x + width / 2, labelY);

                    if (cue.label.toUpperCase().startsWith("N")) {
                        if (root.cueNLabels && nIdx < root.cueNLabels.length) {
                            var nLabel = root.cueNLabels[nIdx];
                            if (nLabel) {
                                ctx.save();
                                ctx.font = "bold 21px sans-serif";
                                ctx.fillStyle = Theme.primary(Material.theme);
                                ctx.fillText(nLabel, x + width / 2, labelY + 16);
                                ctx.restore();
                            }
                        }
                        nIdx++;
                    }
                }
            }

            // Draw datasets
            // Build a color palette for datasets. Priority:
            // 1) dataset.color property, 2) root.datasetColors, 3) theme graph palette, 4) generated HSL colors
            var graphicsPalette = Theme.chartPalette(Material.theme);
            var colors = [];
            for (var i = 0; i < datasets.length; i++) {
                var color = null;
                if (datasets[i] && datasets[i].color) {
                    color = datasets[i].color;
                } else if (root.datasetColors && root.datasetColors.length > i) {
                    color = root.datasetColors[i];
                } else if (i < graphicsPalette.length) {
                    color = graphicsPalette[i];
                } else {
                    var hue = (i * 360 / datasets.length) % 360;
                    color = "hsl(" + hue + ", 60%, 50%)";
                }
                colors.push(color);
            }

            ctx.save();
            ctx.beginPath();
            ctx.rect(leftMargin, topPadding, graphWidth, graphHeight);
            ctx.clip();

            for (var d = 0; d < datasets.length; d++) {
                var data = datasets[d];
                if (data.length < 2)
                    continue;

                ctx.beginPath();
                ctx.moveTo(scaleX(data[0].x), scaleY(data[0].y, d));

                for (var i = 1; i < data.length; i++) {
                    // Simple optimization: skip points if they map to same pixel?
                    // For now, just draw all.
                    ctx.lineTo(scaleX(data[i].x), scaleY(data[i].y, d));
                }

                ctx.strokeStyle = colors[d % colors.length];
                ctx.lineWidth = root.lineWidth;
                ctx.lineJoin = "round";
                ctx.stroke();
            }
            ctx.restore();
        }
    }

    onWaveDataChanged: {
        canvas.requestPaint();
    }

    onCuePointsChanged: {
        canvas.requestPaint();
    }

    onIndependentScaleChanged: {
        canvas.requestPaint();
    }

    onDatasetColorsChanged: {
        canvas.requestPaint();
    }

    onShowCueLabelsChanged: {
        canvas.requestPaint();
    }

    onCueNLabelsChanged: {
        canvas.requestPaint();
    }
}
