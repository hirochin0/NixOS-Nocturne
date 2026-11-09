import QtQuick
import Quickshell

Image {
    id: icon
    property string iconName: ""
    readonly property string resolved: {
        if (iconName.startsWith("/") || iconName.startsWith("file:")) return iconName;
        const themed = Quickshell.iconPath(iconName, true);
        if (themed) return themed;
        const name = iconName.replace(/\.desktop$/, "");
        return IconCatalog.icons[name] || IconCatalog.icons[name.toLowerCase()] || Qt.resolvedUrl("application.svg");
    }
    source: resolved
    sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
    sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
    fillMode: Image.PreserveAspectFit
    smooth: true
    onStatusChanged: if (status === Image.Error) source = Qt.resolvedUrl("application.svg")
}
