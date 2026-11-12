local binds = {}
local dispatcher = setmetatable({}, {__index = function(_, name) return function(...) return {name=name,args={...}} end end})
hl = {
    bind = function(keys, action, flags) binds[keys] = {action=action,flags=flags or {}} end,
}
-- Ignore unrelated dispatchers, while keeping the real key-registration code.
hl.dsp = setmetatable({window=dispatcher}, {__index=function(_, name) return dispatcher[name] end})
local commands=setmetatable({launcher="launcher",desktopToggle="desktop"},{__index=function() return "command" end})
assert(loadfile(arg[1]))()({commands=commands})
assert(binds.Super_L.flags.release and binds.Super_R.flags.release)
assert(binds.Super_L.action.args[1]=="launcher")
assert(binds["SUPER + D"].action.args[1]=="desktop")
assert(not binds["SUPER + CTRL + D"])
assert(binds["SUPER + Return"] and binds["SUPER + 1"])
print("Super release launcher, Super+D desktop and existing shortcuts passed.")
