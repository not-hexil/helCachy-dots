pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config

StyledRect {
    id: root

    required property var note

    radius: Appearance.rounding.large
    color: Qt.alpha(root.note.color, 0.15)

    // Colored left accent bar
    StyledRect {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 3
        radius: root.radius
        color: root.note.color
    }

    Column {
        anchors {
            fill: parent
            margins: Appearance.padding.normal
            leftMargin: Appearance.padding.normal + 6
        }
        spacing: Appearance.spacing.small
        clip: true

        // Title + actions row
        Row {
            width: parent.width
            spacing: Appearance.spacing.small / 2

            TextInput {
                id: titleInput
                width: parent.width - colorDot.width - deleteBtn.width - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                text: root.note.title
                font.pointSize: Appearance.font.size.normal
                font.family: Appearance.font.family.sans
                font.weight: Font.SemiBold
                color: Colours.palette.m3onSurface
                clip: true
                selectByMouse: true

                onEditingFinished: ClipboardManager.updateNote(root.note.id, { title: text })
            }

            // Color dot
            Rectangle {
                id: colorDot
                anchors.verticalCenter: parent.verticalCenter
                width: 14; height: 14
                radius: 7
                color: root.note.color
                border.width: colorPicker.visible ? 2 : 0
                border.color: Colours.palette.m3onSurface

                MouseArea {
                    anchors.fill: parent
                    onClicked: colorPicker.visible = !colorPicker.visible
                }
            }

            ClipIconButton {
                id: deleteBtn
                anchors.verticalCenter: parent.verticalCenter
                icon: "delete"
                onClicked: ClipboardManager.deleteNote(root.note.id)
            }
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.alpha(root.note.color, 0.35)
        }

        // Content area
        Flickable {
            width: parent.width
            height: parent.height - titleInput.height - 1 - parent.spacing * 2
            clip: true
            contentHeight: contentEdit.implicitHeight

            TextEdit {
                id: contentEdit
                width: parent.width
                text: root.note.content
                wrapMode: TextEdit.Wrap
                font.pointSize: Appearance.font.size.smaller
                font.family: Appearance.font.family.sans
                color: Colours.palette.m3onSurface
                selectByMouse: true

                StyledText {
                    visible: !contentEdit.text
                    text: "Write something…"
                    font.pointSize: Appearance.font.size.smaller
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: 0.5
                }

                onTextChanged: saveDebounce.restart()
            }
        }
    }

    // Color picker popup
    StyledRect {
        id: colorPicker
        visible: false
        z: 10
        anchors { bottom: parent.top; right: parent.right; bottomMargin: 4 }
        height: 34
        width: ClipboardManager.noteColors.length * 22 + (ClipboardManager.noteColors.length - 1) * 4 + Appearance.padding.small * 2
        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainerHighest

        Row {
            anchors { fill: parent; margins: Appearance.padding.small }
            spacing: 4

            Repeater {
                model: ClipboardManager.noteColors

                delegate: Rectangle {
                    required property string modelData
                    width: 22; height: 22
                    radius: 11
                    color: modelData
                    border.width: root.note.color === modelData ? 2 : 0
                    border.color: Colours.palette.m3onSurface

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            ClipboardManager.updateNote(root.note.id, { color: modelData })
                            colorPicker.visible = false
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 800
        onTriggered: ClipboardManager.updateNote(root.note.id, { content: contentEdit.text })
    }
}
