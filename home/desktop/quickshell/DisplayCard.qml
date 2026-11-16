import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "DisplayLogic.js" as DisplayLogic

Pane {
    id: card
    property var displays: []
    property int selected: 0
    property real viewCenterX: 0
    property real viewCenterY: 0
    property real viewZoom: 1
    property bool viewReady: false
    function fitView() {
        if (!displays.length || map.width <= 48 || map.height <= 40) return;
        const extent = DisplayLogic.bounds(displays);
        const sizes = displays.map(d => DisplayLogic.size(d));
        // Keep room for a monitor on every side, rather than filling the canvas.
        viewCenterX = extent.x + extent.width / 2;
        viewCenterY = extent.y + extent.height / 2;
        viewZoom = Math.max(0.005, Math.min(2, (map.width - 48) / (extent.width + 2 * Math.max(...sizes.map(s => s.width))),
                           (map.height - 40) / (extent.height + 2 * Math.max(...sizes.map(s => s.height)))));
        viewReady = true;
    }
    onDisplaysChanged: if (!viewReady && displays.length) Qt.callLater(fitView)
    property bool busy: false
    property bool previewing: false
    property int remaining: 0
    property string error: ""
    property string notice: ""
    readonly property var current: displays[selected] || null
    signal editRequested(int index, var patch)
    signal reloadRequested()
    signal applyRequested()
    signal keepRequested()
    signal revertRequested()
    signal closeRequested()
    component SettingCombo: ComboBox {
        background: Rectangle { radius: 12; color: Theme.elevated; border.color: parent.activeFocus ? Theme.cyan : "transparent" }
        indicator: Text { x: parent.width - width - 12; y: (parent.height - height) / 2; text: "⌄"; color: Theme.cyan; font.pixelSize: 18 }
    }
    component SettingSpin: SpinBox {
        id: spin
        background: Rectangle { radius: 12; color: Theme.bg; border.color: spin.activeFocus ? Theme.cyan : "transparent" }
        up.indicator: Rectangle {
            x: spin.width - width; width: 36; height: spin.height; radius: 12; color: Theme.elevated
            Text { anchors.centerIn: parent; text: "+"; color: Theme.text; font.pixelSize: 22 }
        }
        down.indicator: Rectangle {
            width: 36; height: spin.height; radius: 12; color: Theme.elevated
            Text { anchors.centerIn: parent; text: "−"; color: Theme.text; font.pixelSize: 22 }
        }
    }
    padding: 24
    palette.window: Theme.surface
    palette.base: Theme.bg
    palette.button: Theme.elevated
    palette.text: Theme.text
    palette.buttonText: Theme.text
    palette.windowText: Theme.text
    palette.highlight: Theme.cyan
    palette.highlightedText: Theme.bg
    font.family: Theme.roundFont
    font.pixelSize: 14
    background: Rectangle { color: Theme.surface; radius: 28; border.color: Qt.alpha(Theme.muted, 0.25) }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 2
                Label { text: "Displays"; font.pixelSize: 28; font.bold: true }
                Label { text: "NOCTURNE  /  モニター設定"; color: Theme.muted; font.pixelSize: 12 }
            }
            Item { Layout.fillWidth: true }
            BarButton { text: "再読み込み"; enabled: !card.busy && !card.previewing; onClicked: card.reloadRequested() }
            BarButton { text: "✕"; hint: "閉じる / Esc"; onClicked: card.closeRequested() }
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "ドラッグで自由配置 · 空白をドラッグで移動"; color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.Wrap }
                    BarButton { text: "−"; hint: "縮小"; onClicked: card.viewZoom = Math.max(0.005, card.viewZoom / 1.25) }
                    BarButton { text: "+"; hint: "拡大"; onClicked: card.viewZoom = Math.min(2, card.viewZoom * 1.25) }
                    BarButton { text: "全体表示"; onClicked: card.fitView() }
                }
                Rectangle {
                    id: map
                    onWidthChanged: if (!card.viewReady) Qt.callLater(card.fitView)
                    onHeightChanged: if (!card.viewReady) Qt.callLater(card.fitView)
                    Layout.fillWidth: true
                    Layout.preferredHeight: 290
                    color: Theme.bg; radius: 20
                    clip: true
                    readonly property real factor: card.viewZoom
                    readonly property real originX: width / 2 - card.viewCenterX * factor
                    readonly property real originY: height / 2 - card.viewCenterY * factor
                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        property point pointer
                        property real centerX
                        property real centerY
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        onPressed: mouse => { pointer = Qt.point(mouse.x, mouse.y); centerX = card.viewCenterX; centerY = card.viewCenterY; }
                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            card.viewCenterX = centerX - (mouse.x - pointer.x) / map.factor;
                            card.viewCenterY = centerY - (mouse.y - pointer.y) / map.factor;
                        }
                        onWheel: wheel => {
                            card.viewZoom = Math.max(0.005, Math.min(2, card.viewZoom * (wheel.angleDelta.y > 0 ? 1.15 : 1 / 1.15)));
                            wheel.accepted = true;
                        }
                    }
                    Repeater {
                        model: card.displays
                        Rectangle {
                            id: monitor
                            objectName: "display-map-" + modelData.name
                            required property var modelData
                            required property int index
                            readonly property var logicalSize: DisplayLogic.size(modelData)
                            x: map.originX + modelData.x * map.factor + pointer.dragX
                            y: map.originY + modelData.y * map.factor + pointer.dragY
                            width: logicalSize.width * map.factor
                            height: logicalSize.height * map.factor
                            z: pointer.pressed ? 2 : index === card.selected ? 1 : 0
                            radius: 12
                            color: index === card.selected ? Qt.alpha(Theme.cyan, 0.19) : Theme.elevated
                            border.color: index === card.selected ? Theme.cyan : Qt.alpha(Theme.muted, 0.5)
                            border.width: index === card.selected ? 2 : 1
                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                spacing: 4
                                Text { width: parent.width; text: (monitor.modelData.internal ? "Laptop · " : "Display · ") + monitor.modelData.name; color: Theme.text; font.family: Theme.roundFont; font.bold: true; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                                Text { width: parent.width; text: monitor.modelData.mode.replace("@", " · ") + " Hz"; color: Theme.muted; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                            }
                            MouseArea {
                                id: pointer
                                anchors.fill: parent
                                enabled: !card.busy && !card.previewing
                                preventStealing: true
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                property real dragX: 0
                                property real dragY: 0
                                property real factor: 1
                                property point offset: Qt.point(0, 0)
                                onPressed: mouse => {
                                    card.selected = monitor.index;
                                    offset = mapToItem(map, mouse.x, mouse.y);
                                    factor = map.factor;
                                    dragX = 0; dragY = 0;
                                }
                                onPositionChanged: mouse => {
                                    if (!pressed) return;
                                    const point = mapToItem(map, mouse.x, mouse.y);
                                    dragX = point.x - offset.x;
                                    dragY = point.y - offset.y;
                                }
                                onReleased: {
                                    if (Math.abs(dragX) + Math.abs(dragY) < 3) { dragX = 0; dragY = 0; return; }
                                    const patch = DisplayLogic.drop(card.displays, monitor.index,
                                        monitor.modelData.x + dragX / factor, monitor.modelData.y + dragY / factor, 14 / factor);
                                    dragX = 0; dragY = 0;
                                    card.editRequested(monitor.index, patch);
                                }
                                onCanceled: { dragX = 0; dragY = 0; }
                            }
                        }
                    }
                    Label { anchors.centerIn: parent; visible: !card.displays.length; text: card.busy ? "接続情報を取得中…" : "モニターがありません"; color: Theme.muted }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: card.displays
                        BarButton {
                            required property var modelData
                            required property int index
                            text: modelData.name
                            tint: index === card.selected ? Theme.cyan : Theme.text
                            onClicked: card.selected = index
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
                Label { Layout.fillWidth: true; text: card.current ? card.current.description : ""; color: Theme.muted; elide: Text.ElideRight }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 16; rowSpacing: 12
                    enabled: !!card.current && !card.busy && !card.previewing
                    Label { text: "解像度" }
                    SettingCombo {
                        id: resolution
                        objectName: "display-resolution"
                        Layout.fillWidth: true
                        model: card.current ? DisplayLogic.resolutions(card.current) : []
                        currentIndex: card.current ? model.indexOf(card.current.mode.split("@")[0]) : -1
                        onActivated: {
                            const mode = DisplayLogic.modes(card.current).filter(m => m.resolution === currentText).sort((a,b) => b.hz - a.hz)[0];
                            if (mode) card.editRequested(card.selected, {mode: mode.mode});
                        }
                    }
                    Label { text: "リフレッシュレート" }
                    SettingCombo {
                        Layout.fillWidth: true
                        objectName: "display-refresh"
                        model: card.current ? DisplayLogic.rates(card.current).map(m => m.hz.toFixed(3) + " Hz") : []
                        currentIndex: card.current ? DisplayLogic.rates(card.current).findIndex(m => Math.abs(m.hz - Number(card.current.mode.split("@")[1])) < 0.001) : -1
                        onActivated: index => card.editRequested(card.selected, {mode: DisplayLogic.rates(card.current)[index].mode})
                    }
                    Label { text: "表示倍率" }
                    SettingSpin {
                        Layout.fillWidth: true
                        objectName: "display-scale"
                        from: 50; to: 300; stepSize: 25; editable: true
                        value: card.current ? Math.round(card.current.scale * 100) : 100
                        textFromValue: value => value + " %"
                        valueFromText: text => Number(text.replace(/[^0-9]/g, ""))
                        onValueModified: card.editRequested(card.selected, {scale: value / 100})
                    }
                    Label { text: "回転" }
                    SettingCombo {
                        Layout.fillWidth: true
                        model: ["標準 · 0°", "90°", "180°", "270°", "反転 · 0°", "反転 · 90°", "反転 · 180°", "反転 · 270°"]
                        currentIndex: card.current ? card.current.transform : 0
                        onActivated: index => card.editRequested(card.selected, {transform: index})
                    }
                    Label { text: "X 座標" }
                    SettingSpin { Layout.fillWidth: true; from: -32768; to: 32768; editable: true; value: card.current ? card.current.x : 0; onValueModified: card.editRequested(card.selected, {x: value}) }
                    Label { text: "Y 座標" }
                    SettingSpin { Layout.fillWidth: true; from: -32768; to: 32768; editable: true; value: card.current ? card.current.y : 0; onValueModified: card.editRequested(card.selected, {y: value}) }
                }
                RowLayout {
                    visible: card.displays.length > 1
                    enabled: !card.busy && !card.previewing
                    Layout.fillWidth: true
                    Label { text: "配置基準"; color: Theme.muted }
                    SettingCombo {
                        id: reference
                        Layout.preferredWidth: 140
                        model: card.displays.filter(m => m.name !== (card.current ? card.current.name : "")).map(m => m.name)
                    }
                    Repeater {
                        model: [{title: "左", direction: "left"}, {title: "右", direction: "right"}, {title: "上", direction: "above"}, {title: "下", direction: "below"}]
                        BarButton {
                            required property var modelData
                            text: modelData.title
                            onClicked: {
                                const other = card.displays.find(m => m.name === reference.currentText);
                                if (card.current && other) card.editRequested(card.selected, DisplayLogic.place(card.current, other, modelData.direction));
                            }
                        }
                    }
                }
            }
        }
        Label { Layout.fillWidth: true; visible: card.error.length > 0; text: card.error; color: Theme.yellow; wrapMode: Text.Wrap; font.pixelSize: 12 }
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: card.previewing ? "この設定を保持しますか？ " + card.remaining + " 秒で元に戻ります" : card.notice || "変更後に15秒間のプレビューを行います"
                color: card.previewing ? Theme.cyan : Theme.muted
                wrapMode: Text.Wrap
                font.pixelSize: 12
            }
            Button { text: "元に戻す"; visible: card.previewing; enabled: !card.busy; onClicked: card.revertRequested() }
            Button { objectName: "display-apply"; text: card.previewing ? "保持" : "適用して確認"; highlighted: true; enabled: !card.busy && card.displays.length > 0; onClicked: card.previewing ? card.keepRequested() : card.applyRequested() }
        }
    }
}
