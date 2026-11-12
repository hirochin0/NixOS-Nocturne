import QtQuick
import QtTest
import Quickshell
import "file://@bundle@"
ShellRoot {
    FloatingWindow {
        implicitWidth: 240; implicitHeight: 135
        color: "transparent"
        DinoGame {
            id: game; anchors.fill: parent; automatic: false
            bestScore: DinoScores.bestScore
            onRecordRequested: value => DinoScores.record(value)
        }
        TestCase { id: input; name: "DinoInput"; when: false }
        Timer {
            interval: 400; running: true
            onTriggered: {
                if (game.width !== 240 || game.height !== 135 || game.phase !== "idle") throw new Error("Bad initial game");
                input.mouseClick(game, 120, 85);
                if (game.phase !== "running") throw new Error("Click did not start game");
                input.keyClick(Qt.Key_Space);
                for (let i = 0; i < 20; i++) game.advance(1 / 120);
                if (game.world.height < 20) throw new Error("Space did not jump");
                input.keyClick(Qt.Key_Escape);
                if (game.phase !== "paused") throw new Error("Pause failed");
                const distance = game.world.distance;
                game.advance(0.1);
                if (game.world.distance !== distance) throw new Error("Paused game kept moving");
                input.mouseClick(game, 120, 85);
                for (let i = 0; i < 700; i++) game.advance(1 / 120);
                if (game.phase !== "over" || game.score <= 0) throw new Error("Collision or score failed");
                if (DinoScores.bestScore < game.score) throw new Error("Best score not recorded");
                DinoScores.record(321); DinoScores.record(12);
                if (DinoScores.bestScore !== 321) throw new Error("Best score decreased");
                input.mouseClick(game, 120, 85);
                if (game.phase !== "running" || game.score !== 0) throw new Error("Retry failed");
                console.log("NOCTURNE_DINO_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
