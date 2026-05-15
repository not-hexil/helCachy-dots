pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config

StyledRect {
    id: root

    required property var item

    property bool hovered: false

    height: cardRow.implicitHeight + Appearance.padding.normal * 2
    radius: Appearance.rounding.normal
    color: hovered ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer

    Behavior on color { CAnim {} }

    // Color swatch stripe for color-type entries
    StyledRect {
        visible: root.item.type === "color"
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 3
        radius: root.radius
        color: {
            try { return root.item.text.trim() } catch(e) { return "transparent" }
        }
    }

    Row {
        id: cardRow
        anchors {
            left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
            leftMargin: root.item.type === "color"
                ? Appearance.padding.normal + 6
                : Appearance.padding.normal
            rightMargin: Appearance.padding.small
        }
        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                switch(root.item.type) {
                    case "link":  return "link"
                    case "color": return "palette"
                    case "image": return "image"
                    default:      return "notes"
                }
            }
            color: Colours.palette.m3primary
            opacity: 0.8
        }

        StyledText {
            width: parent.width
                - parent.spacing * 4
                - 24          // type icon
                - (root.hovered ? 28 + 28 : 0) // pin + delete
                - 28          // copy always visible
            anchors.verticalCenter: parent.verticalCenter
            text: root.item.text
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pointSize: Appearance.font.size.normal
            font.family: Appearance.font.family.sans
            color: Colours.palette.m3onSurface
        }

        // Pin/unpin  (hover only)
        ClipIconButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hovered
            icon: ClipboardManager.isPinned(root.item.id) ? "push_pin" : "push_pin"
            highlighted: ClipboardManager.isPinned(root.item.id)
            onClicked: {
                if (ClipboardManager.isPinned(root.item.id))
                    ClipboardManager.unpinItem(root.item.id)
                else
                    ClipboardManager.pinItem(root.item)
            }
        }

        // Delete (hover only)
        ClipIconButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hovered
            icon: "delete"
            onClicked: ClipboardManager.deleteItem(root.item.id)
        }

        // Copy (always visible)
        ClipIconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "content_copy"
            highlighted: true
            onClicked: ClipboardManager.copyItem(root.item.id)
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: (mouse) => {
            ClipboardManager.copyItem(root.item.id)
            mouse.accepted = false
        }
    }
}
