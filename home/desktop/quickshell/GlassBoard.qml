import QtQuick
import QtQuick.Effects

Item {
    id: board
    property real cornerRadius: Math.min(height / 2, 32)
    property real lightX: width * 0.24
    readonly property bool software: GraphicsInfo.api === GraphicsInfo.Software
    Behavior on lightX { SmoothedAnimation { duration: 180; velocity: -1 } }
    onLightXChanged: lens.requestPaint()
    Rectangle {
        x: 1; y: 3
        width: Math.max(0, board.width - 2); height: board.height
        radius: board.cornerRadius
        color: "#18000c35"
    }
    Rectangle { anchors.fill: parent; radius: board.cornerRadius; color: "#482354ab" }
    Image {
        id: backdrop
        source: Theme.wallpaperPath
        sourceSize: Qt.size(640, 400)
        width: board.width; height: board.height
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        layer.enabled: !board.software
    }
    Rectangle { id: mask; anchors.fill: parent; radius: board.cornerRadius; color: "white"; visible: false; layer.enabled: !board.software }
    MultiEffect {
        anchors.fill: parent
        visible: !board.software && backdrop.status === Image.Ready
        source: backdrop
        blurEnabled: true; blurMax: 32; blur: 0.8
        saturation: 0.05
        opacity: 0.34
        maskEnabled: true; maskSource: mask
        autoPaddingEnabled: false
    }
    // Reflections belong to this decorative surface, behind the preview.
    Canvas {
        id: lens
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections { target: board; function onCornerRadiusChanged() { lens.requestPaint(); } }
        function contour(ctx, inset) {
            const r = Math.max(0, Math.min(board.cornerRadius - inset, (width - inset * 2) / 2, (height - inset * 2) / 2));
            const left = inset, top = inset, right = width - inset, bottom = height - inset;
            ctx.beginPath();
            ctx.moveTo(left + r, top);
            ctx.arcTo(right, top, right, bottom, r);
            ctx.arcTo(right, bottom, left, bottom, r);
            ctx.arcTo(left, bottom, left, top, r);
            ctx.arcTo(left, top, right, top, r);
            ctx.closePath();
        }
        onPaint: {
            if (width < 2 || height < 2) return;
            const ctx = getContext("2d");
            ctx.reset();
            contour(ctx, 0.5);
            ctx.save();
            ctx.clip();
            const blue = ctx.createLinearGradient(0, 0, 0, height);
            blue.addColorStop(0, "rgba(108,163,255,0.30)");
            blue.addColorStop(0.43, "rgba(30,84,193,0.12)");
            blue.addColorStop(1, "rgba(7,16,91,0.42)");
            ctx.fillStyle = blue;
            ctx.fillRect(0, 0, width, height);
            const glowX = Math.max(0, Math.min(width, board.lightX * 0.45));
            const glow = ctx.createRadialGradient(glowX, height * 0.55, 0, glowX, height * 0.55, Math.max(height, width * 0.68));
            glow.addColorStop(0, "rgba(218,251,255,0.46)");
            glow.addColorStop(0.38, "rgba(171,226,255,0.22)");
            glow.addColorStop(1, "rgba(153,204,255,0)");
            ctx.fillStyle = glow;
            ctx.fillRect(0, 0, width, height);
            const rim = ctx.createLinearGradient(0, 0, width, height);
            rim.addColorStop(0, "rgba(247,255,255,0.90)");
            rim.addColorStop(0.46, "rgba(193,221,255,0.46)");
            rim.addColorStop(0.72, "rgba(123,158,246,0.20)");
            rim.addColorStop(1, "rgba(212,232,255,0.62)");
            contour(ctx, 2.5);
            ctx.strokeStyle = "rgba(193,223,255,0.12)";
            ctx.lineWidth = 6;
            ctx.stroke();
            contour(ctx, 1.2);
            ctx.strokeStyle = "rgba(204,231,255,0.16)";
            ctx.lineWidth = 3;
            ctx.stroke();
            contour(ctx, 0.8);
            ctx.strokeStyle = rim;
            ctx.lineWidth = 1.2;
            ctx.stroke();
            ctx.restore();
        }
    }
}
