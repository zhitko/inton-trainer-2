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
            
            // Assuming audio sample values are normalized between -1 and 1
            var minY = -1.0;
            var maxY = 1.0;

            function scaleX(x) {
                return (x - minX) / (maxX - minX) * canvas.width;
            }

            function scaleY(y) {
                // Y is inverted in canvas, so we subtract from height
                var scaledY = (y - minY) / (maxY - minY);
                return canvas.height * (1 - scaledY);
            }
            
            // Draw cue points
            ctx.lineWidth = 1;
            ctx.font = "10px sans-serif";
            ctx.textAlign = "center";

            for (var i = 0; i < root.cuePoints.length; i++) {
                var cue = root.cuePoints[i];
                var x = scaleX(cue.position);
                var width = scaleX(cue.position + cue.sampleLength) - x;

                if (cue.label.startsWith("P")) {
                    ctx.fillStyle = "rgba(237, 106, 90, 0.3)";
                    ctx.strokeStyle = "#ed6a5a";
                } else if (cue.label.startsWith("N")) {
                    ctx.fillStyle = "rgba(244, 241, 187, 0.3)";
                    ctx.strokeStyle = "#f4f1bb";
                } else if (cue.label.startsWith("T")) {
                    ctx.fillStyle = "rgba(155, 193, 188, 0.3)";
                    ctx.strokeStyle = "#9bc1bc";
                } else {
                    ctx.fillStyle = "rgba(255, 0, 0, 0.3)";
                    ctx.strokeStyle = "red";
                }

                var labelHeight = 20;
                // Draw rectangle
                ctx.beginPath();
                ctx.rect(x, 0, width, canvas.height - labelHeight);
                ctx.fill();
                ctx.stroke();

                // Draw label
                ctx.fillStyle = "black";
                ctx.fillText(cue.label, x + width / 2, canvas.height - 5);
            }
            
            ctx.beginPath();
            ctx.moveTo(scaleX(root.waveData[0].x), scaleY(root.waveData[0].y));

            for (var i = 1; i < root.waveData.length; i+=8) {
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
