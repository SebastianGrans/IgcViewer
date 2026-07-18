import QtQuick

Rectangle {
    id: root

    property string label: ""
    property bool active: false
    property int labelPixelSize: 10
    property alias hovered: hoverArea.containsMouse

    signal clicked

    width: 30
    height: 30
    radius: 5
    color: root.active ? "#0369a1" : (hoverArea.containsMouse ? "#2563eb" : "#1d4ed8")
    z: 10

    Text {
        anchors.centerIn: parent
        text: root.label
        color: "#f1f5f9"
        font.pixelSize: root.labelPixelSize
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
