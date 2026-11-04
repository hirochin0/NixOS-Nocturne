return function(settings)
    local t = settings.theme
    local function rgb(hex) return "rgb(" .. hex .. ")" end
    hl.config({
        general = {
            gaps_in = 6, gaps_out = 14, border_size = 2,
            col = {
                active_border = { colors = { rgb(t.accent), rgb(t.cyan) }, angle = 45 },
                inactive_border = rgb(t.elevated),
            },
            layout = "dwindle", resize_on_border = true,
        },
        decoration = {
            rounding = t.radius, active_opacity = 1.0, inactive_opacity = 0.97,
            blur = { enabled = true, size = 5, passes = 2, vibrancy = 0.15 },
            shadow = { enabled = true, range = 20, render_power = 3, color = "rgba(00000055)" },
        },
        animations = { enabled = true },
        dwindle = { preserve_split = true },
        misc = { disable_hyprland_logo = true, disable_splash_rendering = true, vrr = 0 },
    })
end
