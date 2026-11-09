.pragma library

function duration(seconds) {
    if (!Number.isFinite(seconds) || seconds <= 0) return "";
    var minutes = Math.floor(seconds / 60);
    if (minutes < 1) return "<1 min";
    var hours = Math.floor(minutes / 60);
    minutes = minutes % 60;
    return hours ? hours + " h" + (minutes ? " " + minutes + " min" : "") : minutes + " min";
}

function percentage(value, ready, present) {
    return ready && present && Number.isFinite(value)
        ? Math.round(Math.max(0, Math.min(1, value)) * 100) + "%" : "—";
}

function estimate(ready, present, discharging, charging, full, timeToEmpty, timeToFull) {
    if (!ready) return "Calculating remaining time…";
    if (!present) return "No battery detected";
    if (full) return "Fully charged";
    if (charging) {
        var charge = duration(timeToFull);
        return charge ? charge + " until full" : "Charging · estimating time…";
    }
    if (discharging) {
        var remaining = duration(timeToEmpty);
        return remaining ? remaining + " remaining" : "Estimating remaining time…";
    }
    return "Plugged in";
}
