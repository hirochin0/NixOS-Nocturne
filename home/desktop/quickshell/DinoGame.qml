import QtQuick
import "DinoLogic.js" as Runner

FocusScope {
    id: game
    implicitWidth: 240
    implicitHeight: 135
    clip: true
    property var world: Runner.create()
    property int revision: 0
    property int bestScore: 0
    property bool automatic: true
    readonly property string phase: { revision; return world.phase; }
    readonly property int score: { revision; return world.score; }
    signal recordRequested(int value)

    function refresh() { revision++; scenery.requestPaint(); }
    function activate() {
        if (phase === "paused") Runner.resume(world);
        else if (phase !== "running") { world = Runner.create(); Runner.start(world); }
        else Runner.jump(world);
        refresh();
        clock.lastFrame = Date.now();
        forceActiveFocus();
    }
    function jump() { Runner.jump(world); refresh(); }
    function pause() {
        if (phase !== "running") return;
        Runner.pause(world); refresh(); recordRequested(score);
    }
    function advance(seconds) {
        const previous = phase;
        Runner.advance(world, seconds);
        refresh();
        if (previous === "running" && phase === "over") recordRequested(score);
    }
    onActiveFocusChanged: if (!activeFocus) pause()
    onVisibleChanged: if (!visible) pause()
    Component.onDestruction: recordRequested(score)
    Connections {
        target: game.Window.window
        function onActiveChanged() { if (!game.Window.window.active) game.pause(); }
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space) {
            if (!event.isAutoRepeat) game.jump();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            game.pause(); event.accepted = true;
        }
    }
    Timer {
        id: clock
        property double lastFrame: 0
        interval: 16
        repeat: true
        running: game.automatic && game.visible && game.phase === "running"
        onRunningChanged: lastFrame = Date.now()
        onTriggered: {
            const now = Date.now();
            game.advance((now - lastFrame) / 1000);
            lastFrame = now;
        }
    }
    Text {
        objectName: "dino-score"
        anchors { top: parent.top; topMargin: 5; horizontalCenter: parent.horizontalCenter }
        text: String(game.score).padStart(5, "0")
        color: "#e4edf7"
        font { family: Theme.font; pixelSize: 13; bold: true }
        style: Text.Outline; styleColor: "#7020293c"
    }
    Text {
        anchors { right: parent.right; rightMargin: 3; top: parent.top; topMargin: 25 }
        text: "HI " + String(Math.max(game.bestScore, game.score)).padStart(5, "0")
        color: "#a8b7cc"
        font { family: Theme.font; pixelSize: 8 }
        style: Text.Outline; styleColor: "#7020293c"
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 48 }
        visible: game.phase !== "running"
        text: game.phase === "over" ? "GAME OVER\nCLICK TO RETRY"
            : game.phase === "paused" ? "PAUSED · CLICK TO RESUME" : "CLICK TO RUN\nSPACE TO JUMP"
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.25
        color: "#d2e0ef"
        font { family: Theme.font; pixelSize: 8; bold: true }
        style: Text.Outline; styleColor: "#9020293c"
    }
    Canvas {
        id: scenery
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const world = game.world;
            const ground = 110;
            // Only the desert scenery and sprites are painted; the rest stays transparent.
            ctx.fillStyle = "#8195ae";
            ctx.fillRect(0, ground, width, 1);
            for (let i = 0; i < 14; i++) {
                const x = ((i * 23 - world.distance) % 322 + 322) % 322;
                ctx.fillRect(x, ground + 4 + (i % 3) * 3, i % 2 ? 4 : 2, 1);
            }
            ctx.strokeStyle = "#65778f";
            ctx.lineWidth = 1;
            for (let i = 0; i < 2; i++) {
                const x = ((167 + i * 126 - world.distance * 0.13) % 300 + 300) % 300;
                const y = 43 + i * 24;
                ctx.beginPath(); ctx.moveTo(x, y + 5); ctx.lineTo(x + 6, y + 5);
                ctx.lineTo(x + 6, y + 2); ctx.lineTo(x + 10, y + 2);
                ctx.lineTo(x + 10, y); ctx.lineTo(x + 17, y);
                ctx.lineTo(x + 21, y + 5); ctx.lineTo(x + 28, y + 5); ctx.stroke();
            }
            ctx.fillStyle = "#a8c7c7";
            for (let i = 0; i < world.obstacles.length; i++) {
                const o = world.obstacles[i];
                const x = Math.round(o.x), y = ground - o.height;
                const stem = Math.round(o.width / 2) - 2;
                ctx.fillRect(x + stem, y, 4, o.height);
                ctx.fillRect(x, y + 5, 3, 9);
                ctx.fillRect(x, y + 11, stem, 3);
                ctx.fillRect(x + o.width - 3, y + 3, 3, 8);
                ctx.fillRect(x + stem + 4, y + 8, o.width - stem - 4, 3);
            }
            const sprite = [
                "000000111110", "000001111111", "000001101111", "000001111111",
                "000001111000", "100011111000", "110111111110", "111111111010",
                "011111111000", "001111110000", "000111110000", "000110110000"
            ];
            const top = Math.round(ground - 28 - world.height);
            ctx.fillStyle = "#d6eced";
            for (let y = 0; y < sprite.length; y++) {
                for (let x = 0; x < sprite[y].length; x++) {
                    if (sprite[y][x] === "1") ctx.fillRect(22 + x * 2, top + y * 2, 2, 2);
                }
            }
            const stride = game.phase === "running" && world.height === 0
                ? Math.floor(world.distance / 8) % 2 : 0;
            ctx.fillRect(28, top + 24, 3, stride ? 2 : 4);
            ctx.fillRect(34, top + 24, 3, stride ? 4 : 2);
            ctx.fillRect(stride ? 34 : 28, top + 27, 5, 1);
        }
        Component.onCompleted: requestPaint()
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: game.activate()
    }
}
