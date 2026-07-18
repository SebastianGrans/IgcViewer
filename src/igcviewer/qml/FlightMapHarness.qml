import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 900
    height: 600
    title: "FlightMap dev harness"
    color: Theme.windowBg

    FlightMap {
        anchors.fill: parent
        maximized: false
        onToggleMaximize: {}
    }
}
