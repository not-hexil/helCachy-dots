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

        // Header row
        Row {
            width: parent.width

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notes"
                font.pointSize: Appearance.font.size.normal
                font.family: Appearance.font.family.sans
                color: Colours.palette.m3onSurfaceVariant
            }

            Item { width: parent.width - parent.childrenRect.width - addBtn.width; height: 1 }

            // Add note button
            StyledRect {
                id: addBtn
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                width: addRow.implicitWidth + Appearance.padding.normal * 2
                radius: Appearance.rounding.full
                color: addArea.pressed
                    ? Colours.palette.m3primaryContainer
                    : Colours.palette.m3surfaceContainerHigh

                Behavior on color { CAnim {} }

                Row {
                    id: addRow
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small / 2

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "add"
                        color: Colours.palette.m3primary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "New note"
                        font.pointSize: Appearance.font.size.smaller
                        font.family: Appearance.font.family.sans
                        color: Colours.palette.m3onSurface
                    }
                }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    onClicked: ClipboardManager.addNote("New note")
                }
            }
        }

        // Empty state
        Item {
            width: parent.width
            height: parent.height - parent.spacing - 28
            visible: ClipboardManager.noteCards.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "sticky_note_2"
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.4
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No notes yet"
                    font.pointSize: Appearance.font.size.normal
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.6
                }
            }
        }

        // 2-column grid
        GridView {
            id: grid
            width: parent.width
            height: parent.height - parent.spacing - 28
            visible: ClipboardManager.noteCards.length > 0
            clip: true
            cellWidth:  width / 2
            cellHeight: 140

            model: ClipboardManager.noteCards

            delegate: NoteCard {
                required property var modelData
                width:  grid.cellWidth  - Appearance.spacing.small / 2
                height: grid.cellHeight - Appearance.spacing.small / 2
                note: modelData
            }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Appearance.anim.durations.expressiveEffects }
                NumberAnimation { property: "scale";   from: 0.9; to: 1; duration: Appearance.anim.durations.expressiveEffects }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: Appearance.anim.durations.small }
            }
        }
    }
}
