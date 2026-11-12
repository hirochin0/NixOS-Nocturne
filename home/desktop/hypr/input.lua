return function(settings)
    hl.config({ input = {
        kb_layout = settings.keyboardLayout, follow_mouse = 1, sensitivity = 0,
        touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true },
    } })
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    local function revealGesture(direction, command)
        hl.gesture({ fingers = 3, direction = direction, action = {
            finish = function(event)
                if not event.cancelled then
                    hl.dispatch(hl.dsp.exec_cmd(command))
                end
            end,
        } })
    end
    revealGesture("up", settings.commands.desktopShow)
    revealGesture("down", settings.commands.desktopHide)
end
