import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: root
    visible: true
    width: 900
    height: 500
    title: "AltitudeChart dev harness"
    color: Theme.windowBg

    AltitudeChartV2 {
        anchors.fill: parent
        anchors.margins: 12
    }
}
