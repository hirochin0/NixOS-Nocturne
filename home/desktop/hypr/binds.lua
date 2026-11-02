-- Hyprland 0.55 Lua API. Nixを介さず読みやすい形で管理。
local mod = "SUPER + "
local function run(key, cmd)
  hl.bind(key, hl.dsp.exec_cmd(cmd))
end
run(mod .. "Return", "kitty")
run(mod .. "B", "firefox")
run(mod .. "E", "thunar")
run(mod .. "D", "nocturne-launcher")
run(mod .. "L", "nocturne-lock")
run(mod .. "SHIFT + E", "nocturne-power")
run(mod .. "SHIFT + S", "nocturne-screenshot")
run("Print", "nocturne-screenshot")
run(mod .. "SHIFT + R", "hyprctl reload")
hl.bind(mod .. "Q", hl.dsp.window.close())
hl.bind(mod .. "F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. "Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. "P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(mod .. "J", hl.dsp.layout("togglesplit"))
for key, direction in pairs({ left = "left", right = "right", up = "up", down = "down" }) do
  hl.bind(mod .. key, hl.dsp.focus({ direction = direction }))
  hl.bind(mod .. "SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end
for i = 1, 9 do
  hl.bind(mod .. tostring(i), hl.dsp.focus({ workspace = tostring(i) }))
  hl.bind(mod .. "SHIFT + " .. tostring(i), hl.dsp.window.move({ workspace = tostring(i), follow = true }))
end
hl.bind(mod .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. "mouse:273", hl.dsp.window.resize(), { mouse = true })
run("XF86AudioRaiseVolume", "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+")
run("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
run("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
run("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
run("XF86MonBrightnessUp", "brightnessctl set +5%")
run("XF86MonBrightnessDown", "brightnessctl set 5%-")
run("XF86AudioPlay", "playerctl play-pause")
run("XF86AudioNext", "playerctl next")
run("XF86AudioPrev", "playerctl previous")
