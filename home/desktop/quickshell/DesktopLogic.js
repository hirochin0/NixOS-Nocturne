.pragma library
function target(window, screenWidth, screenHeight) {
    const left = window.x + window.width / 2 <= screenWidth / 2;
    const top = window.y + window.height / 2 <= screenHeight / 2;
    return {x: left ? -window.width - 32 : screenWidth + 32,
        y: top ? -window.height - 32 : screenHeight + 32};
}
function canonicalAddress(value) {
    return String(value || "").replace(/^0x/i, "").replace(/^0+(?=[0-9a-f])/i, "").toLowerCase();
}
function windows(plan, handles) {
    return plan.windows.map(function(window) {
        const handle = handles.find(function(h) { return canonicalAddress(h.address) === canonicalAddress(window.address); });
        return {x: window.at[0] - plan.monitorX, y: window.at[1] - plan.monitorY,
            width: window.size[0], height: window.size[1], source: handle ? handle.wayland : null,
            address: window.address};
    });
}
