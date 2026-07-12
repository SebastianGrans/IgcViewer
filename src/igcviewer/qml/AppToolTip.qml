import QtQuick
import QtQuick.Controls

ToolTip {
    id: root
    padding: 6
    delay: 500

    contentItem: Text {
        text: root.text
        color: Theme.textPrimary
        font.pointSize: Theme.fontSm
    }
    background: Rectangle {
        color: Theme.surfaceLow
        border.color: Theme.divider
        border.width: 1
        radius: 4
    }
}
