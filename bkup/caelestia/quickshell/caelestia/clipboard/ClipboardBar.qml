pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config

// Drop into your bar layout:
//   import "clipboard"
//   ClipboardBar {}
StyledRect {
    id: root

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: row.implicitHeight + Appearance.padding.normal * 2
    radius: Appearance.rounding.full

    color: Qt.alpha(
        Colours.tPalette.m3secondaryContainer,
        ClipboardManager.panelOpen ? Colours.tPalette.m3secondaryContainer.a : 0
    )

    Behavior on color { CAnim {} }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "content_paste"
            color: ClipboardManager.panelOpen
                ? Colours.palette.m3onSecondaryContainer
                : Colours.palette.m3onSurface

            Behavior on color { CAnim {} }
        }

        // Pinned badge
        StyledRect {
            anchors.verticalCenter: parent.verticalCenter
            visible: ClipboardManager.pinnedItems.length > 0
            width: Math.max(16, badgeTxt.implicitWidth + 6)
            height: 16
            radius: Appearance.rounding.full
            color: Colours.palette.m3primary

            StyledText {
                id: badgeTxt
                anchors.centerIn: parent
                text: ClipboardManager.pinnedItems.length
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.sans
                color: Colours.palette.m3onPrimary
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ClipboardManager.toggle()
    }
}
