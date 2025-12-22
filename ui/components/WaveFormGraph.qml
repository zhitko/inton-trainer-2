import QtQuick 2.15
import QtQuick.Controls.Material 6.8
import "../utils"

Item {
    id: root
    width: 300
    height: 150

    property var waveData: []
    property var cuePoints: []

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

            // Find global min/max for scaling
            var minX = datasets[0][0].x;
            var maxX = datasets[0][datasets[0].length - 1].x;
            var minY = datasets[0][0].y;
            var maxY = datasets[0][0].y;

            for (var d = 0; d < datasets.length; d++) {
                var data = datasets[d];
                if (data.length > 0) {
                    if (data[0].x < minX)
                        minX = data[0].x;
                    if (data[data.length - 1].x > maxX)
                        maxX = data[data.length - 1].x;

                    for (var i = 0; i < data.length; i++) {
                        var y = data[i].y;
                        if (y < minY)
                            minY = y;
                        if (y > maxY)
                            maxY = y;
                    }
                }
            }

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
            var bottomPadding = 20;
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

            function scaleY(y) {
                // Y is inverted in canvas, so we subtract from height
                let scaledY = (y - minY) / rangeY * graphHeight;
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
                ctx.strokeStyle = "black";
                ctx.lineWidth = 1;
                ctx.stroke();

                // Draw label
                ctx.fillStyle = Theme.onSurfaceVariant(Material.theme);
                ctx.textAlign = "right";
                ctx.fillText("0", leftMargin - 8, y0);
            }

            for (var i = 0; i < root.cuePoints.length; i++) {
                var cue = root.cuePoints[i];
                var x = scaleX(cue.position);
                var width = scaleX(cue.position + cue.length) - x;

                if (cue.label.toUpperCase().startsWith("P")) {
                    ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
                    ctx.strokeStyle = 'rgb(176, 190, 197)';
                } else if (cue.label.toUpperCase().startsWith("N")) {
                    ctx.fillStyle = 'rgba(76, 175, 80, 0.2)';
                    ctx.strokeStyle = 'rgb(165, 214, 167)';
                } else if (cue.label.toUpperCase().startsWith("T")) {
                    ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
                    ctx.strokeStyle = 'rgb(176, 190, 197)';
                } else {
                    ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
                    ctx.strokeStyle = 'rgb(176, 190, 197)';
                }

                // Draw rectangle
                ctx.beginPath();
                ctx.rect(x, topPadding, width, graphHeight);
                ctx.fill();
                ctx.stroke();

                // Draw label
                ctx.fillStyle = Theme.onSurface(Material.theme);
                ctx.fillText(cue.label, x + width / 2, canvas.height - bottomPadding / 2);
            }

            // Draw datasets
            var colors = [Theme.primary(Material.theme), Theme.secondary(Material.theme), Theme.tertiary(Material.theme), Theme.error(Material.theme), Theme.primaryContainer(Material.theme), Theme.secondaryContainer(Material.theme)];

            ctx.save();
            ctx.beginPath();
            ctx.rect(leftMargin, topPadding, graphWidth, graphHeight);
            ctx.clip();

            for (var d = 0; d < datasets.length; d++) {
                var data = datasets[d];
                if (data.length < 2)
                    continue;

                ctx.beginPath();
                ctx.moveTo(scaleX(data[0].x), scaleY(data[0].y));

                for (var i = 1; i < data.length; i++) {
                    // Simple optimization: skip points if they map to same pixel?
                    // For now, just draw all.
                    ctx.lineTo(scaleX(data[i].x), scaleY(data[i].y));
                }

                ctx.strokeStyle = colors[d % colors.length];
                ctx.lineWidth = 1.5;
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
}
