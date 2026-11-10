const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const logic = vm.createContext({});
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, ''), logic);
const qml = fs.readFileSync(process.argv[3], 'utf8');
const body = qml.slice(qml.indexOf('    function focusWindow(window) {'), qml.indexOf('    function switchWorkspace'));
for (const usingLua of [false, true]) {
  const calls = [];
  const context = vm.createContext({
    FocusLogic: logic, Hyprland: {usingLua},
    root: {dispatch: request => calls.push(request)},
    workspaceFor: window => window.workspace || null,
    console,
  });
  vm.runInContext(body, context);
  context.focusWindow({address: '0xabc123',
    workspace: {activate() {throw new Error('Addressed window should use a single compositor request');}},
    wayland: {activate() {throw new Error('Wayland activation must not override compositor focus');}},
  });
  assert.deepEqual(calls, [usingLua ? 'hl.dsp.focus({ window = "address:0xabc123" })' : 'focuswindow address:0xabc123']);
  calls.length = 0;
  context.focusWindow({address: 'abc456', wayland: null});
  assert.equal(calls[0], logic.request('abc456', usingLua));
  calls.length = 0;
  context.focusWindow({address: '', workspace: {activate() {calls.push('workspace');}}, wayland: {activate() {calls.push('window');}}});
  assert.deepEqual(calls, ['workspace', 'window']);
}
for (const invalid of ['', '0', '0x0', 'no-address', 'abc; def']) assert.equal(logic.request(invalid, true), '');
console.log('Focus dispatch tests passed for Lua and legacy modes, with and without Wayland handles.');
