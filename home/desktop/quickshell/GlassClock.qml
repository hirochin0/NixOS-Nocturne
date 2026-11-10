import QtQuick
import "ClockLogic.js" as ClockLogic

Item {
    id: clock
    implicitWidth: 900
    implicitHeight: 360
    property url wallpaperSource: Theme.wallpaperPath
    property real desktopWidth: width
    property real desktopHeight: height
    property real desktopX: 0
    property real desktopY: 0
    property date now: new Date()
    property bool ticking: true
    property bool pointerActive: hover.hovered
    property real pointerX: hover.point.position.x
    property real pointerY: hover.point.position.y
    readonly property real digitSize: Math.min(204, Math.max(82, (width - 130) / 2.86))
    readonly property string dailyQuote: ClockLogic.quote(now)
    readonly property string timeText: Qt.formatTime(now, "HH:mm")
    Timer { interval: 1000; repeat: true; running: clock.ticking; onTriggered: clock.now = new Date() }
    HoverHandler { id: hover }
    Image {
        id: wallpaper
        width: clock.desktopWidth
        height: clock.desktopHeight
        source: clock.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        visible: false
        layer.enabled: true
        asynchronous: true
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 28
        text: Qt.locale("en_US").toString(clock.now, "dddd, MMMM d").toUpperCase()
        font { family: Theme.roundFont; pixelSize: 13; weight: Font.Bold; variableAxes: ({"wght": 750}); letterSpacing: 3 }
        color: Qt.alpha("#e2eaff", 0.8)
    }
    Row {
        id: digits
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: -3 }
        spacing: -4
        Repeater {
            model: clock.timeText.split("")
            GlassDigit {
                id: character
                required property string modelData
                required property int index
                objectName: "glass-digit-" + index
                text: modelData
                fontSize: clock.digitSize
                readonly property var field: ClockLogic.tension(clock.pointerX, clock.pointerY, digits.x + character.x + width / 2, digits.y + character.y + height / 2, clock.pointerActive)
                pullX: field.x
                pullY: field.y
                tension: field.amount
                glassSource: wallpaper.status === Image.Ready ? reflection : null
                ShaderEffectSource {
                    id: reflection
                    sourceItem: wallpaper
                    sourceRect: Qt.rect(clock.desktopX + digits.x + character.x - character.pullX * 1.8,
                        clock.desktopY + digits.y + character.y - character.pullY * 1.8, character.width, character.height)
                    textureSize: Qt.size(character.width, character.height)
                    live: clock.pointerActive
                    visible: false
                    onSourceRectChanged: scheduleUpdate()
                    Component.onCompleted: scheduleUpdate()
                    Connections { target: wallpaper; function onStatusChanged() { reflection.scheduleUpdate(); } }
                }
            }
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 62
        width: parent.width - 80
        text: clock.dailyQuote
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font { family: Theme.roundFont; pixelSize: 15; weight: Font.DemiBold; variableAxes: ({"wght": 650}); letterSpacing: 0.5 }
        color: Qt.alpha("#e3eaff", 0.78)
    }
}
