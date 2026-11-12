.pragma library

function parse(lrc) {
    if (typeof lrc !== "string") return [];
    const offset = /\[offset:([+-]?\d+)\]/i.exec(lrc);
    const shift = offset ? Number(offset[1]) / 1000 : 0;
    const entries = [];
    lrc.split(/\r?\n/).slice(0, 5000).forEach(function(line) {
        const tags = /\[(\d{1,3}):([0-5]\d)(?:[.:](\d{1,3}))?\]/g;
        const text = line.replace(/\[[^\]]*\]/g, "").trim();
        let match;
        while ((match = tags.exec(line)) !== null) {
            const time = Number(match[1]) * 60 + Number(match[2])
                + (match[3] ? Number("0." + match[3]) : 0) - shift;
            entries.push({time: Math.max(0, time), text: text});
        }
    });
    entries.sort(function(a, b) { return a.time - b.time; });
    const result = [];
    entries.forEach(function(line) {
        const previous = result[result.length - 1];
        if (previous && previous.time === line.time) {
            if (line.text && previous.text !== line.text) previous.text += (previous.text ? " / " : "") + line.text;
        } else result.push(line);
    });
    return result;
}

function activeIndex(lines, seconds) {
    if (!Number.isFinite(seconds)) return -1;
    let low = 0, high = lines.length - 1, result = -1;
    while (low <= high) {
        const mid = Math.floor((low + high) / 2);
        if (lines[mid].time <= seconds) { result = mid; low = mid + 1; }
        else high = mid - 1;
    }
    return result;
}
