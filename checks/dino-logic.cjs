const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const logic = vm.createContext({});
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, ''), logic);
let world = logic.create();
assert.equal(logic.jump(world), false);
logic.advance(world, 1);
assert.equal(world.distance, 0);
logic.start(world);
assert.equal(logic.jump(world), true);
logic.advance(world, 0.1, () => 0);
assert.ok(world.height > 15);
assert.equal(logic.jump(world), false, 'no double jump');
logic.pause(world);
const frozen = JSON.stringify(world);
logic.advance(world, 0.1);
assert.equal(JSON.stringify(world), frozen);
logic.resume(world);
for (let i = 0; i < 10; i++) logic.advance(world, 0.1, () => 0);
assert.equal(world.height, 0);
world.obstacles = [{x: 44, width: 10, height: 24}];
logic.advance(world, 0.1);
assert.equal(world.phase, 'over');
const ended = JSON.stringify(world);
logic.advance(world, 1);
assert.equal(JSON.stringify(world), ended);
// Every generated cactus / gap remains jumpable, at both initial and capped speed.
for (const distance of [0, 25000]) {
    for (const random of [() => 0, () => 0.999]) {
        world = logic.create(); world.distance = distance; logic.start(world);
        for (let frame = 0; frame < 15000; frame++) {
            const next = world.obstacles.find(o => o.x + o.width > 29);
            if (next && next.x < 43 + world.speed * 0.22 && world.height === 0) logic.jump(world);
            logic.advance(world, 1 / 120, random);
            assert.equal(world.phase, 'running', `unavoidable cactus at distance ${world.distance}`);
        }
        assert.ok(world.score > 1000);
        assert.ok(world.obstacles.length < 5);
    }
}
world = logic.create(); logic.start(world); world.distance = 25000;
world.obstacles = [{x: 48, width: 10, height: 20}];
logic.advance(world, 4, () => 0);
assert.equal(world.phase, 'over', 'delayed frames still detect collisions');
console.log('Start, jump, landing, pause/resume, collision, score, cleanup and jumpable gaps passed.');
