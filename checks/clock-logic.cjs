const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const logic = vm.createContext({});
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, ''), logic);
const morning = new Date(2026, 10, 10, 0, 1);
const evening = new Date(2026, 10, 10, 23, 59);
assert.equal(logic.quote(morning), logic.quote(evening));
assert.equal(logic.dayKey(new Date(2026, 10, 11)), '2026-11-11');
const quotes = new Set(Array.from({length: 30}, (_, i) => logic.quote(new Date(2026, 10, i + 1))));
assert.ok(quotes.size > 8);
for (let x = -1000; x < 1000; x += 20) {
  const field = logic.tension(x, 10, 100, 100, true);
  assert.ok(Math.abs(field.x) <= 12 && Math.abs(field.y) <= 10);
  assert.ok(field.amount >= 0 && field.amount <= 1);
}
assert.equal(JSON.stringify(logic.tension(10, 20, 100, 100, false)), '{"x":0,"y":0,"amount":0}');
console.log('Daily quote stability, selection range and bounded cursor response passed.');
