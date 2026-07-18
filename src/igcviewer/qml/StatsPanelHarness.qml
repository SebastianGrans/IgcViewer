import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 900
    height: 300
    title: "StatsPanel dev harness"
    color: Theme.windowBg

    StatsPanel {
        anchors.fill: parent
        mapMaximized: false
    }
}
