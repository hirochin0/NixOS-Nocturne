import QtQuick
import Quickshell
import "IconLogic.js" as IconLogic

Image {
    id: icon
    property string iconName: ""
    property int candidateIndex: 0
    readonly property var candidates: {
        const sources = [];
        if (iconName.startsWith("/") || iconName.startsWith("file:")) sources.push(iconName);
        else {
            const pinned = Theme.appIconOverrides[IconLogic.normalize(iconName)];
            if (pinned) sources.push(pinned);
            for (const name of IconLogic.names(iconName)) {
                if (IconCatalog.userIcons[name]) sources.push(IconCatalog.userIcons[name]);
                if (IconCatalog.icons[name]) sources.push(IconCatalog.icons[name]);
                const themed = Quickshell.iconPath(name, true);
                if (themed) sources.push(themed);
            }
        }
        sources.push(String(Qt.resolvedUrl("application.svg")));
        return [...new Set(sources)];
    }
    onCandidatesChanged: candidateIndex = 0
    source: candidates[Math.min(candidateIndex, candidates.length - 1)] || ""
    sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
    sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
    fillMode: Image.PreserveAspectFit
    smooth: true
    // Keep the source binding alive while catalogs load or the window app id changes.
    onStatusChanged: if (status === Image.Error) Qt.callLater(function() {
        if (icon.status === Image.Error && icon.candidateIndex + 1 < icon.candidates.length)
            icon.candidateIndex++;
    })
}
