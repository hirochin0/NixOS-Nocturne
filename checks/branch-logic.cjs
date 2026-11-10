const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const logic = vm.createContext({});
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, ''), logic);
const apps = JSON.parse(fs.readFileSync(process.argv[3], 'utf8')).apps;
assert.equal(apps.length, 10);
assert.deepEqual(apps.map((_, index) => logic.parentIndex(apps, index)).filter(parent => parent === -1), [-1, -1, -1]);
const childCount = new Map();
for (let i = 0; i < 10; i++) {
    const parent = logic.parentIndex(apps, i);
    assert.ok(parent < i && parent >= -1);
    childCount.set(parent, (childCount.get(parent) || 0) + 1);
    assert.ok(logic.depth(apps, i) >= 1 && logic.depth(apps, i) <= 3);
    const parentIndex = logic.parentIndex(apps, i);
    if (parentIndex >= 0) assert.ok(logic.openDelay(apps, i) > logic.openDelay(apps, parentIndex));
    const p = logic.position(i);
    const start = parentIndex >= 0 ? logic.position(parentIndex) : {x: 60, y: 60};
    assert.ok(Math.abs(p.x - start.x) > 25 && Math.abs(p.y - start.y) > 25, 'Branch should have an oblique angle');
    for (let j = 0; j < i; j++) {
        const other = logic.position(j);
        assert.ok(Math.abs(p.x - other.x) > 64 || Math.abs(p.y - other.y) > 88, 'Overlapping application nodes');
    }
}
assert.ok([...childCount].filter(([parent, count]) => parent >= 0 && count >= 2).length >= 3);
assert.equal(logic.parentIndex([{parent: 99}], 0), -1);
console.log('10 nodes, acyclic parent graph, multiple branch points and non-overlapping app bounds passed.');
