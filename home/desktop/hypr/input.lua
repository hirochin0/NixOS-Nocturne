return function(settings)
    hl.config({ input = {
        kb_layout = settings.keyboardLayout, follow_mouse = 1, sensitivity = 0,
        touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true },
    } })
end
