-- Hyprland v0.57.1. 値はgenerated.lua、操作はbinds.lua、外観はappearance.lua。
local root = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/"
local settings = dofile(root .. "generated.lua")
-- 操作を先に登録。装飾設定の不具合でターミナルのキーまで失わない。
dofile(root .. "binds.lua")(settings)
for _, monitor in ipairs(settings.monitors) do hl.monitor(monitor) end
-- The display editor saves a writable, atomic set of overrides after confirmation.
local displays = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/nocturne/displays.lua"
local file = io.open(displays, "r")
if file then
    file:close()
    local ok, err = pcall(dofile, displays)
    if not ok then print("NOCTURNE display settings: " .. tostring(err)) end
end
dofile(root .. "appearance.lua")(settings)
dofile(root .. "input.lua")(settings)
