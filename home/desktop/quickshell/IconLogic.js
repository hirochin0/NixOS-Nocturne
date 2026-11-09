.pragma library
function normalize(value) { return String(value || "").replace(/\.desktop$/i, "").toLowerCase().replace(/[^a-z0-9]/g, ""); }
function names(value) {
    const raw = String(value || "").replace(/\.desktop$/i, "");
    const result = [raw, raw.toLowerCase()];
    const aliases = {
        chromechatgptcomdefault: ["chatgpt", "google-chrome"],
        code: ["vscode", "visual-studio-code"], codeoss: ["code-oss", "vscode"],
        googlechrome: ["google-chrome", "chrome"], chromiumbrowser: ["chromium", "chromium-browser"],
        orggnomenautilus: ["org.gnome.Nautilus", "nautilus"],
        orgwezfurlongwezterm: ["org.wezfurlong.wezterm", "wezterm"],
        comdiscordappdiscord: ["discord"], comspotifyclient: ["spotify"],
        mdobsidianobsidian: ["obsidian"]
    };
    for (const name of aliases[normalize(raw)] || []) result.push(name);
    if (raw.includes(".")) result.push(raw.split(".").pop().toLowerCase());
    if (/^steam_app_/i.test(raw)) result.push("steam");
    return [...new Set(result)];
}
function findEntry(appId, entries) {
    const ids = names(appId).map(normalize).filter(id => id.length > 0);
    if (ids.length === 0) return null;
    return entries.find(e => normalize(e.id) === ids[0])
        || entries.find(e => ids.includes(normalize(e.startupClass)) && !!e.startupClass)
        || entries.find(e => ids.includes(normalize(e.id)))
        || entries.find(e => ids.includes(normalize(e.name)) && !!e.name) || null;
}
