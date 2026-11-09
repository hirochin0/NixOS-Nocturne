pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: catalog
    property var icons: ({})
    property FileView reader: FileView {
        path: Theme.iconIndexPath
        onLoaded: { try { catalog.icons = JSON.parse(text()); } catch (e) {} }
    }
}
