function dimensions(sourceWidth, sourceHeight, screenWidth, screenHeight) {
    const maxWidth = Math.max(1, Math.min(1000, screenWidth - 32));
    const maxHeight = Math.max(1, Math.min(900, screenHeight - 90));
    const padding = Math.min(16, maxWidth / 6, maxHeight / 6);
    const heading = Math.min(66, maxHeight / 4);
    const w = sourceWidth > 0 ? sourceWidth : 1280;
    const h = sourceHeight > 0 ? sourceHeight : 800;
    const scale = Math.max(0, Math.min(1, (Math.min(900, maxWidth) - padding * 2) / w, (maxHeight - padding * 2 - heading) / h));
    return {width: Math.max(1, Math.floor(w * scale + padding * 2)),
        height: Math.max(1, Math.floor(h * scale + padding * 2 + heading)),
        imageWidth: w * scale, imageHeight: h * scale, padding: padding, heading: heading};
}
function windowSize(window) {
    const size = window && window.lastIpcObject && window.lastIpcObject.size;
    return size && size.length === 2 && size[0] > 0 && size[1] > 0 ? {width: size[0], height: size[1]} : {width: 1280, height: 800};
}
