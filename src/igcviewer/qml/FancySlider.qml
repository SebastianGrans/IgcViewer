import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property real value: 0.0
    property real from: 0.0
    property real to: 1.0
    property string label: ""
    property int labelPixelSize: 10

    onValueChanged: slider.value = value

    spacing: 6

    function applyWheel(event) {
        var step = (root.to - root.from) / 20;
        root.value = Math.max(root.from, Math.min(root.to, root.value + event.angleDelta.y / 120 * step));
        // Prevent the wheel event from being propagated (i.e. end up zoomin the cesium view)
        event.accepted = true;
    }

    HoverHandler {
        id: rootHover
    }

    Slider {
        id: slider
        visible: toggleBtn.active || rootHover.hovered
        from: root.from
        to: root.to
        implicitWidth: 100
        Component.onCompleted: value = root.value
        onMoved: root.value = value

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: Theme.divider

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: "#1d4ed8"
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 16
            height: 16
            radius: 4
            color: slider.pressed ? "#0369a1" : (slider.hovered ? "#2563eb" : "#1d4ed8")
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: event => root.applyWheel(event)
        }
    }

    Rectangle {
        id: toggleBtn
        property bool active: false
        implicitWidth: 30
        implicitHeight: 30
        radius: 5
        color: active ? "#0369a1" : (rootHover.hovered ? "#2563eb" : "#1d4ed8")

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
            onClicked: toggleBtn.active = !toggleBtn.active
            onWheel: event => root.applyWheel(event)
        }
    }
}
