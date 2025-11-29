import QtQuick 2.15

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

            if (root.waveData.length < 2) {
                return;
            }

            // Find min/max for scaling
            var minX = root.waveData[0].x;
            var maxX = root.waveData[root.waveData.length - 1].x;

            // Calculate min/max Y from data
            var minY = root.waveData[0].y;
            var maxY = root.waveData[0].y;

            for (var i = 1; i < root.waveData.length; i++) {
                var y = root.waveData[i].y;
                if (y < minY)
                    minY = y;
                if (y > maxY)
                    maxY = y;
            }

            // Add some padding
            var range = maxY - minY;
            if (range === 0) {
                range = 1.0;
            }

            // Reserve space for Y axis and paddings
            var leftMargin = 40;
            var topPadding = 10;
            var bottomPadding = 20;
            var graphWidth = canvas.width - leftMargin;
            var graphHeight = canvas.height - topPadding - bottomPadding;

            function scaleX(x) {
                return leftMargin + (x - minX) / (maxX - minX) * graphWidth;
            }

            function scaleY(y) {
                // Y is inverted in canvas, so we subtract from height
                var scaledY = (y - minY) / (maxY - minY);
                return topPadding + graphHeight * (1 - scaledY);
            }

            // Draw Y axis
            ctx.strokeStyle = "black";
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
            ctx.fillStyle = "black";
            ctx.font = "10px sans-serif";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillText(maxY.toFixed(2), leftMargin - 8, topPadding);
            ctx.fillText(minY.toFixed(2), leftMargin - 8, canvas.height - bottomPadding);

            // Draw cue points
            ctx.lineWidth = 1;
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            for (var i = 0; i < root.cuePoints.length; i++) {
                var cue = root.cuePoints[i];
                var x = scaleX(cue.position);
                var width = scaleX(cue.position + cue.sampleLength) - x;

                if (cue.label.toUpperCase().startsWith("P")) {
                    ctx.fillStyle = "rgba(237, 106, 90, 0.3)";
                    ctx.strokeStyle = "#ed6a5a";
                } else if (cue.label.toUpperCase().startsWith("N")) {
                    ctx.fillStyle = "rgba(244, 241, 187, 0.3)";
                    ctx.strokeStyle = "#f4f1bb";
                } else if (cue.label.toUpperCase().startsWith("T")) {
                    ctx.fillStyle = "rgba(155, 193, 188, 0.3)";
                    ctx.strokeStyle = "#9bc1bc";
                } else {
                    ctx.fillStyle = "rgba(255, 0, 0, 0.3)";
                    ctx.strokeStyle = "red";
                }

                // Draw rectangle
                ctx.beginPath();
                ctx.rect(x, topPadding, width, graphHeight);
                ctx.fill();
                ctx.stroke();

                // Draw label
                ctx.fillStyle = "black";
                ctx.fillText(cue.label, x + width / 2, canvas.height - bottomPadding / 2);
            }

            ctx.beginPath();
            ctx.moveTo(scaleX(root.waveData[0].x), scaleY(root.waveData[0].y));

            for (var i = 1; i < root.waveData.length; i += 2) {
                ctx.lineTo(scaleX(root.waveData[i].x), scaleY(root.waveData[i].y));
            }

            ctx.strokeStyle = "steelblue";
            ctx.lineWidth = 1.5;
            ctx.stroke();
        }
    }

    onWaveDataChanged: {
        canvas.requestPaint();
    }

    onCuePointsChanged: {
        canvas.requestPaint();
    }
}
