.pragma library

// Restrict selection to Spotify so a Chrome video never steals its controls.
function spotifyPlayer(players) {
    var spotify = players.filter(function(p) {
        return /^org\.mpris\.MediaPlayer2\.spotify(?:\.|$)/i.test(p.dbusName || "")
            || /^spotify$/i.test(p.desktopEntry || "");
    });
    return spotify.find(function(p) { return p.isPlaying; }) || spotify[0] || null;
}

function musicScreen(screens, preferred) {
    return screens.find(function(s) { return s.name === preferred; })
        || screens.find(function(s) { return /^(eDP|LVDS|DSI)/i.test(s.name); })
        || screens[0] || null;
}

// Default to every output; an explicit music preference keeps its fallback behavior.
function musicScreens(screens, preferred) {
    if (!preferred) return screens;
    const selected = musicScreen(screens, preferred);
    return selected ? [selected] : [];
}

function timeText(seconds) {
    if (!Number.isFinite(seconds) || seconds < 0) return "--:--";
    var total = Math.floor(seconds);
    return Math.floor(total / 60) + ":" + (total % 60 < 10 ? "0" : "") + total % 60;
}

function seekPosition(fraction, length) {
    if (!Number.isFinite(fraction) || !Number.isFinite(length) || length <= 0) return 0;
    return Math.min(1, Math.max(0, fraction)) * length;
}
