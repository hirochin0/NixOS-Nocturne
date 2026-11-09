pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: catalog
    property var entries: []
    property var userIcons: ({})
    property var icons: ({})
    property Process scanner: Process {
        command: [Theme.iconCatalogCommand]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { const data = JSON.parse(text); catalog.entries = data.entries; catalog.userIcons = data.icons; }
                catch (e) { console.warn("Could not read application icon catalog"); }
            }
        }
    }
    property Timer refresh: Timer { interval: 60000; repeat: true; running: true; onTriggered: if (!catalog.scanner.running) catalog.scanner.running = true }
    property FileView reader: FileView {
        path: Theme.iconIndexPath
        onLoaded: { try { catalog.icons = JSON.parse(text()); } catch (e) {} }
    }
}
