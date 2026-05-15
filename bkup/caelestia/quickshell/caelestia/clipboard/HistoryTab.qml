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

        // ── Search ────────────────────────────────────────────────────
        StyledRect {
            width: parent.width
            height: 36
            radius: Appearance.rounding.full
            color: Colours.palette.m3surfaceContainerHigh

            Row {
                anchors { fill: parent; leftMargin: Appearance.padding.normal; rightMargin: Appearance.padding.normal }
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"
                    color: Colours.palette.m3onSurfaceVariant
                }

                TextInput {
                    id: searchInput
                    width: parent.width - parent.childrenRect.width - (clearBtn.visible ? clearBtn.width + parent.spacing : 0) - parent.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.palette.m3onSurface
                    selectionColor: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.normal
                    font.family: Appearance.font.family.sans

                    onTextChanged: ClipboardManager.searchQuery = text

                    StyledText {
                        anchors.fill: parent
                        text: "Search history…"
                        font.pointSize: Appearance.font.size.normal
                        font.family: Appearance.font.family.sans
                        color: Colours.palette.m3onSurfaceVariant
                        visible: !searchInput.text
                    }
                }

                ClipIconButton {
                    id: clearBtn
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    visible: searchInput.text !== ""
                    onClicked: {
                        searchInput.text = ""
                        ClipboardManager.searchQuery = ""
                    }
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────
        Item {
            width: parent.width
            height: parent.height - 36 - parent.spacing
            visible: ClipboardManager.filteredItems.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "content_paste"
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.4
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ClipboardManager.searchQuery ? "No results" : "No clipboard history"
                    font.pointSize: Appearance.font.size.normal
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.6
                }
            }
        }

        // ── List ──────────────────────────────────────────────────────
        ListView {
            id: list
            width: parent.width
            height: parent.height - 36 - parent.spacing
            visible: ClipboardManager.filteredItems.length > 0
            clip: true
            spacing: Appearance.spacing.small / 2
            model: ClipboardManager.filteredItems

            delegate: HistoryCard {
                required property var modelData
                width: list.width
                item: modelData
            }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Appearance.anim.durations.expressiveEffects }
            }
        }
    }
}
