pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config

StyledRect {
    id: root

    required property string label
    required property string icon
    required property bool active
    signal clicked()

    radius: Appearance.rounding.full
    color: root.active ? Colours.palette.m3secondaryContainer : "transparent"

    Behavior on color { CAnim {} }

    Row {
        anchors.centerIn: parent
        spacing: Appearance.spacing.small / 2

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.active
                ? Colours.palette.m3onSecondaryContainer
                : Colours.palette.m3onSurfaceVariant

            Behavior on color { CAnim {} }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.sans
            color: root.active
                ? Colours.palette.m3onSecondaryContainer
                : Colours.palette.m3onSurfaceVariant

            Behavior on color { CAnim {} }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
