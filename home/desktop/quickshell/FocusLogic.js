.pragma library

function request(address, usingLua) {
    const hex = String(address || "").replace(/^0x/i, "");
    if (!/^[0-9a-f]+$/i.test(hex) || /^0+$/.test(hex)) return "";
    const selector = "address:0x" + hex;
    return usingLua ? 'hl.dsp.focus({ window = "' + selector + '" })' : "focuswindow " + selector;
}
