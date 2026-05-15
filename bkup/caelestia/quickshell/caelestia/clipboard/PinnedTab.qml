pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config

Item {
    clip: true

    Column {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        Row {
            width: parent.width
            spacing: Appearance.spacing.small

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Pinned"
                font.pointSize: Appearance.font.size.normal
                font.family: Appearance.font.family.sans
                color: Colours.palette.m3onSurfaceVariant
            }

            Item { width: parent.width - parent.childrenRect.width - countTxt.width - parent.spacing; height: 1 }

            StyledText {
                id: countTxt
                anchors.verticalCenter: parent.verticalCenter
                text: `${ClipboardManager.pinnedItems.length} item${ClipboardManager.pinnedItems.length !== 1 ? "s" : ""}`
                font.pointSize: Appearance.font.size.smaller
                font.family: Appearance.font.family.sans
                color: Colours.palette.m3onSurfaceVariant
                opacity: 0.6
            }
        }

        // Empty state
        Item {
            width: parent.width
            height: parent.height - parent.spacing - 20
            visible: ClipboardManager.pinnedItems.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "push_pin"
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.4
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Pin items from History"
                    font.pointSize: Appearance.font.size.normal
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.6
                }
            }
        }

        ListView {
            width: parent.width
            height: parent.height - parent.spacing - 20
            visible: ClipboardManager.pinnedItems.length > 0
            clip: true
            spacing: Appearance.spacing.small / 2
            model: ClipboardManager.pinnedItems

            delegate: HistoryCard {
                required property var modelData
                width: ListView.view.width
                item: modelData
            }
        }
    }
}
