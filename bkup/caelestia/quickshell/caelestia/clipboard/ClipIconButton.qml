pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config

// Internal reusable icon button
StyledRect {
    id: root

    required property string icon
    property bool highlighted: false
    signal clicked()

    implicitWidth:  28
    implicitHeight: 28
    radius: Appearance.rounding.full

    color: Qt.alpha(
        highlighted ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest,
        area.pressed ? 1 : area.containsMouse ? 0.6 : 0
    )

    Behavior on color { CAnim {} }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        color: root.highlighted ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
