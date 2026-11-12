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
    action.start({})
    action.update({delta = {y = delta}})
    action.finish({cancelled = cancelled})
end
swipe("up", -70, false)
swipe("down", 70, false)
swipe("up", -20, false)
swipe("up", -70, true)
assert(#calls == 2 and calls[1] == "show" and calls[2] == "hide")
print("Up/down swipe, distance threshold, cancellation and horizontal workspace gesture passed.")
