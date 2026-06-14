import QtQuick 2.15
import QtQuick.Controls.Material 6.8
import "../utils"

Item {
    id: root
    width: 600
    height: 300

    // Input: 2D array where spectrumData[frameIndex][binIndex] = magnitude
    property var spectrumData: []
    property bool useLogScale: true
    property string colorScheme: "viridis" // viridis, plasma, hot, cool

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            if (!root.spectrumData || root.spectrumData.length === 0) {
                return;
            }

            var numFrames = root.spectrumData.length;
            var numBins = root.spectrumData[0].length;

            if (numFrames === 0 || numBins === 0) {
                return;
            }

            // Margins
            var leftMargin = 50;
            var rightMargin = 80;
            var topPadding = 10;
            var bottomPadding = 30;
            var graphWidth = canvas.width - leftMargin - rightMargin;
            var graphHeight = canvas.height - topPadding - bottomPadding;

            // Find min/max values for color mapping
            var minVal = root.spectrumData[0][0];
            var maxVal = root.spectrumData[0][0];

            for (var f = 0; f < numFrames; f++) {
                for (var b = 0; b < numBins; b++) {
                    var val = root.spectrumData[f][b];
                    if (val < minVal)
                        minVal = val;
                    if (val > maxVal)
                        maxVal = val;
                }
            }

            // Apply log scale if enabled
            if (root.useLogScale) {
                minVal = Math.log10(Math.max(minVal, 1e-10));
                maxVal = Math.log10(Math.max(maxVal, 1e-10));
            }

            Logger.debug("Spectrogram - Frames: " + numFrames + ", Bins: " + numBins);
            Logger.debug("Spectrogram - MinVal: " + minVal + ", MaxVal: " + maxVal);

            var valueRange = maxVal - minVal;
            if (valueRange === 0)
                valueRange = 1.0;

            // Draw spectrogram
            var cellWidth = graphWidth / numFrames;
            var cellHeight = graphHeight / numBins;

            for (var f = 0; f < numFrames; f++) {
                for (var b = 0; b < numBins; b++) {
                    var value = root.spectrumData[f][b];

                    // Apply log scale
                    if (root.useLogScale) {
                        value = Math.log10(Math.max(value, 1e-10));
                    }

                    // Normalize to [0, 1]
                    var normalizedValue = (value - minVal) / valueRange;
                    normalizedValue = Math.max(0, Math.min(1, normalizedValue));

                    // Get color based on normalized value
                    var color = getColor(normalizedValue, root.colorScheme);

                    // Draw cell (flip Y axis so low frequencies are at bottom)
                    var x = leftMargin + f * cellWidth;
                    var y = topPadding + (numBins - 1 - b) * cellHeight;

                    ctx.fillStyle = color;
                    ctx.fillRect(x, y, Math.ceil(cellWidth) + 1, Math.ceil(cellHeight) + 1);
                }
            }

            // Draw axes
            ctx.strokeStyle = Theme.outline(Material.theme);
            ctx.lineWidth = 1;

            // Y axis
            ctx.beginPath();
            ctx.moveTo(leftMargin, topPadding);
            ctx.lineTo(leftMargin, canvas.height - bottomPadding);
            ctx.stroke();

            // X axis
            ctx.beginPath();
            ctx.moveTo(leftMargin, canvas.height - bottomPadding);
            ctx.lineTo(canvas.width - rightMargin, canvas.height - bottomPadding);
            ctx.stroke();

            // Labels
            ctx.fillStyle = Theme.onSurfaceVariant(Material.theme);
            ctx.font = "10px sans-serif";

            // Y axis label (Frequency bins)
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillText("0", leftMargin - 5, canvas.height - bottomPadding);
            ctx.fillText(numBins.toString(), leftMargin - 5, topPadding);

            // X axis label (Frames/Time)
            ctx.textAlign = "center";
            ctx.textBaseline = "top";
            ctx.fillText("0", leftMargin, canvas.height - bottomPadding + 5);
            ctx.fillText(numFrames.toString(), canvas.width - rightMargin, canvas.height - bottomPadding + 5);

            // Title labels
            ctx.save();
            ctx.translate(15, canvas.height / 2);
            ctx.rotate(-Math.PI / 2);
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Frequency Bins", 0, 0);
            ctx.restore();

            ctx.textAlign = "center";
            ctx.textBaseline = "top";
            ctx.fillText("Time (Frames)", (leftMargin + canvas.width - rightMargin) / 2, canvas.height - bottomPadding + 20);

            // Draw color scale
            drawColorScale(ctx, canvas.width - rightMargin + 10, topPadding, 30, graphHeight, minVal, maxVal);
        }

        function drawColorScale(ctx, x, y, width, height, minVal, maxVal) {
            var steps = 100;
            var stepHeight = height / steps;

            for (var i = 0; i < steps; i++) {
                var normalizedValue = i / steps;
                var color = getColor(normalizedValue, root.colorScheme);
                ctx.fillStyle = color;
                ctx.fillRect(x, y + height - (i + 1) * stepHeight, width, Math.ceil(stepHeight) + 1);
            }

            // Border
            ctx.strokeStyle = Theme.outline(Material.theme);
            ctx.lineWidth = 1;
            ctx.strokeRect(x, y, width, height);

            // Labels
            ctx.fillStyle = Theme.onSurfaceVariant(Material.theme);
            ctx.font = "9px sans-serif";
            ctx.textAlign = "left";
            ctx.textBaseline = "middle";

            var displayMax = root.useLogScale ? Math.pow(10, maxVal).toExponential(1) : maxVal.toFixed(1);
            var displayMin = root.useLogScale ? Math.pow(10, minVal).toExponential(1) : minVal.toFixed(1);

            ctx.fillText(displayMax, x + width + 5, y);
            ctx.fillText(displayMin, x + width + 5, y + height);
        }

        function getColor(normalizedValue, scheme) {
            // Clamp value
            normalizedValue = Math.max(0, Math.min(1, normalizedValue));

            if (scheme === "viridis") {
                return viridisColor(normalizedValue);
            } else if (scheme === "plasma") {
                return plasmaColor(normalizedValue);
            } else if (scheme === "hot") {
                return hotColor(normalizedValue);
            } else if (scheme === "cool") {
                return coolColor(normalizedValue);
            } else {
                return viridisColor(normalizedValue);
            }
        }

        function viridisColor(t) {
            // Approximation of Viridis colormap
            var r = Math.floor(255 * (0.267004 + t * (0.004874 - 0.267004 + t * (0.329415 - 0.004874))));
            var g = Math.floor(255 * (0.004874 + t * (0.277018 - 0.004874 + t * (0.718701 - 0.277018))));
            var b = Math.floor(255 * (0.329415 + t * (0.753683 - 0.329415 + t * (0.505780 - 0.753683))));
            return "rgb(" + r + "," + g + "," + b + ")";
        }

        function plasmaColor(t) {
            // Approximation of Plasma colormap
            var r = Math.floor(255 * (0.050383 + t * (0.940015 - 0.050383)));
            var g = Math.floor(255 * (0.029803 + t * (0.975158 - 0.029803) * (1 - t)));
            var b = Math.floor(255 * (0.527975 + t * (0.131326 - 0.527975)));
            return "rgb(" + r + "," + g + "," + b + ")";
        }

        function hotColor(t) {
            // Hot colormap: black -> red -> yellow -> white
            var r = Math.floor(255 * Math.min(1, t * 3));
            var g = Math.floor(255 * Math.max(0, Math.min(1, t * 3 - 1)));
            var b = Math.floor(255 * Math.max(0, Math.min(1, t * 3 - 2)));
            return "rgb(" + r + "," + g + "," + b + ")";
        }

        function coolColor(t) {
            // Cool colormap: cyan -> magenta
            var r = Math.floor(255 * t);
            var g = Math.floor(255 * (1 - t));
            var b = 255;
            return "rgb(" + r + "," + g + "," + b + ")";
        }
    }

    onSpectrumDataChanged: {
        canvas.requestPaint();
    }

    onUseLogScaleChanged: {
        canvas.requestPaint();
    }

    onColorSchemeChanged: {
        canvas.requestPaint();
    }

    // Error message when no data
    Text {
        anchors.centerIn: parent
        text: qsTr("No spectrum data available.\nCheck analysis settings (e.g. increase FFT length).")
        color: Theme.onSurfaceVariant(root.Material.theme)
        font.pixelSize: AppScale.fs(16)
        horizontalAlignment: Text.AlignHCenter
        visible: !spectrumData || spectrumData.length === 0
    }
}
