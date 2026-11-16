function modes(display) {
    const result = [];
    for (const value of (display.availableModes || []).concat([display.mode])) {
        const m = /^(\d+)x(\d+)@([\d.]+)(?:Hz)?$/.exec(value);
        if (!m) continue;
        const key = m[1] + "x" + m[2] + "@" + Number(m[3]).toFixed(3);
        if (!result.some(v => v.mode === key)) result.push({mode: key, resolution: m[1] + "x" + m[2], hz: Number(m[3])});
    }
    return result;
}
function resolutions(display) { return [...new Set(modes(display).map(m => m.resolution))]; }
function rates(display) { return modes(display).filter(m => m.resolution === display.mode.split("@")[0]); }
function size(display) {
    const parts = display.mode.split("@")[0].split("x").map(Number);
    if (display.transform % 2) parts.reverse();
    return {width: parts[0] / display.scale, height: parts[1] / display.scale};
}
function bounds(displays) {
    if (!displays.length) return {x: 0, y: 0, width: 1920, height: 1080};
    const left = Math.min(...displays.map(m => m.x));
    const top = Math.min(...displays.map(m => m.y));
    return {x: left, y: top,
        width: Math.max(...displays.map(m => m.x + size(m).width)) - left,
        height: Math.max(...displays.map(m => m.y + size(m).height)) - top};
}
function place(display, reference, direction) {
    const own = size(display), other = size(reference);
    if (direction === "left") return {x: Math.round(reference.x - own.width), y: reference.y};
    if (direction === "right") return {x: Math.round(reference.x + other.width), y: reference.y};
    if (direction === "above") return {x: reference.x, y: Math.round(reference.y - own.height)};
    return {x: reference.x, y: Math.round(reference.y + other.height)};
}

// Snap close edges, including diagonal corners, without restricting directions.
function drop(displays, index, x, y, tolerance) {
    const own = size(displays[index]);
    let bestX = tolerance, bestY = tolerance;
    let resultX = x, resultY = y;
    displays.forEach((other, i) => {
        if (i === index) return;
        const s = size(other);
        [other.x - own.width, other.x, other.x + s.width - own.width, other.x + s.width].forEach(edge => {
            if (Math.abs(edge - x) < bestX) { bestX = Math.abs(edge - x); resultX = edge; }
        });
        [other.y - own.height, other.y, other.y + s.height - own.height, other.y + s.height].forEach(edge => {
            if (Math.abs(edge - y) < bestY) { bestY = Math.abs(edge - y); resultY = edge; }
        });
    });
    return {x: Math.round(resultX), y: Math.round(resultY)};
}
