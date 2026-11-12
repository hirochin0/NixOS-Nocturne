local input = assert(loadfile(arg[1]))()
local gestures, calls = {}, {}
hl = {
    config = function() end,
    gesture = function(value) gestures[value.direction] = value end,
    dsp = {exec_cmd = function(command) return command end},
    dispatch = function(command) table.insert(calls, command) end,
}
input({keyboardLayout = "jp", commands = {desktopShow = "show", desktopHide = "hide"}})
assert(gestures.horizontal.action == "workspace")
local function swipe(direction, delta, cancelled)
    local action = gestures[direction].action
    if action.start then action.start({delta = {y = delta}}) end
    if action.update then action.update({delta = {y = delta}}) end
    action.finish({cancelled = cancelled})
end
swipe("up", -70, false)
swipe("down", 70, false)
swipe("up", -20, false)
swipe("up", -70, true)
assert(#calls == 3 and calls[1] == "show" and calls[2] == "hide" and calls[3] == "show")
print("Up/down swipe, short recognized swipe, cancellation and horizontal workspace gesture passed.")
