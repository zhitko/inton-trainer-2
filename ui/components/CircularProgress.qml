import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    property real progress: 0.0 // 0.0 to 1.0
    property color color: "#00FF00"
    property color backgroundColor: "#E0E0E0"
    property real lineWidth: 10
    property bool roundCap: true

    // Internal property for animation
    property real animatedProgress: progress

    Behavior on animatedProgress {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutQuad
        }
    }

    onProgressChanged: {
        canvas.requestPaint();
    }

    onAnimatedProgressChanged: {
        canvas.requestPaint();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            var w = width;
            var h = height;
            var centerX = w / 2;
            var centerY = h / 2;
            var radius = Math.min(w, h) / 2 - root.lineWidth / 2;

            ctx.reset();

            // Draw background circle
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
            ctx.lineWidth = root.lineWidth;
            ctx.strokeStyle = root.backgroundColor;
            ctx.stroke();

            // Draw progress arc
            var startAngle = -Math.PI / 2;
            var endAngle = startAngle + (root.animatedProgress * 2 * Math.PI);

            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
            ctx.lineWidth = root.lineWidth;
            ctx.strokeStyle = root.color;
            if (root.roundCap) {
                ctx.lineCap = "round";
            }
            ctx.stroke();
        }
    }
}
