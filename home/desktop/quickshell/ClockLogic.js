.pragma library
// Original short daily prompts; no API or network dependency.
const sayings = [
    "Make room for what matters.", "Small steps still move you forward.",
    "Let curiosity lead the way.", "Begin where you are.",
    "A little courage changes the day.", "Give your best ideas a little time.",
    "Build something that feels like you.", "Stay gentle. Keep going.",
    "Progress grows in quiet moments.", "Choose a direction, then take a step.",
    "Notice the good you almost missed.", "Leave space for something unexpected.",
    "Your next chapter starts with today.", "Keep the wonder. Do the work.",
    "Take your time, but take the first step.", "The little things become the big things.",
    "A calm mind makes room for possibility.", "Let today be a fresh beginning.",
    "Try, learn, and try a little differently.", "Create more than you consume.",
    "One thoughtful choice can change your day.", "Find a little beauty in the ordinary.",
    "Be patient with what you are becoming.", "Good things grow with attention."
];
function dayKey(date) { return date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate(); }
function quote(date) {
    let seed = 2166136261;
    for (const c of dayKey(date)) seed = Math.imul(seed ^ c.charCodeAt(0), 16777619) >>> 0;
    return sayings[seed % sayings.length];
}
function tension(x, y, centerX, centerY, active) {
    if (!active) return { x: 0, y: 0, amount: 0 };
    const dx = x - centerX, dy = y - centerY;
    const amount = Math.max(0, 1 - Math.sqrt(dx * dx + dy * dy) / 230);
    return {x: Math.max(-12, Math.min(12, dx * 0.085)) * amount,
        y: Math.max(-10, Math.min(10, dy * 0.07)) * amount, amount: amount};
}
