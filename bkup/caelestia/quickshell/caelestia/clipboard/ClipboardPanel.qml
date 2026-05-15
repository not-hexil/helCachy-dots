pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.config

PanelWindow {
    id: root

    // Overlay layer, request keyboard so Escape works
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth:  380
    implicitHeight: panelContent.implicitHeight

    // Anchor top-right; adjust topMargin to match your bar height
    anchors.right: true
    anchors.top: true
    margins.top: Math.round(Config.bar.sizes.outerHeight + Appearance.spacing.small)
    margins.right: Appearance.spacing.small

    visible: ClipboardManager.panelOpen
    color: "transparent"

    Keys.onEscapePressed: ClipboardManager.close()

    StyledRect {
        id: panelContent

        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: col.implicitHeight + Appearance.padding.large * 2
        radius: Appearance.rounding.large
        color: Colours.palette.m3surface

        // Animate height open/close
        states: State {
            name: "open"
            when: ClipboardManager.panelOpen
            PropertyChanges {
                panelContent.opacity: 1
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "open"
                Anim {
                    target: panelContent
                    property: "opacity"
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            },
            Transition {
                from: "open"
                to: ""
                Anim {
                    target: panelContent
                    property: "opacity"
                    duration: Appearance.anim.durations.expressiveEffects
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        ]

        Column {
            id: col
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Appearance.padding.large
            }
            spacing: Appearance.spacing.normal

            // ── Header ────────────────────────────────────────────────
            Row {
                width: parent.width
                spacing: Appearance.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "content_paste"
                    color: Colours.palette.m3primary
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard"
                    font.pointSize: Appearance.font.size.larger
                    font.family: Appearance.font.family.sans
                    color: Colours.palette.m3onSurface
                }

                Item { width: parent.width - parent.childrenRect.width - refreshBtn.width - closeBtn.width - parent.spacing * 3; height: 1 }

                ClipIconButton {
                    id: refreshBtn
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "refresh"
                    onClicked: ClipboardManager.refreshHistory()
                }

                ClipIconButton {
                    id: closeBtn
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    onClicked: ClipboardManager.close()
                }
            }

            // ── Tab bar ───────────────────────────────────────────────
            StyledRect {
                width: parent.width
                height: 36
                radius: Appearance.rounding.full
                color: Colours.palette.m3surfaceContainerHigh

                Row {
                    anchors { fill: parent; margins: 3 }
                    spacing: 0

                    Repeater {
                        model: [
                            { label: "History", icon: "history"       },
                            { label: "Pinned",  icon: "push_pin"      },
                            { label: "Notes",   icon: "sticky_note_2" }
                        ]

                        delegate: ClipTabButton {
                            required property var modelData
                            required property int index
                            width: parent.width / 3
                            height: parent.height
                            label: modelData.label
                            icon:  modelData.icon
                            active: ClipboardManager.activeTab === index
                            onClicked: ClipboardManager.activeTab = index
                        }
                    }
                }
            }

            // ── Tab content ───────────────────────────────────────────
            Item {
                width: parent.width
                height: 460

                HistoryTab  { anchors.fill: parent; visible: ClipboardManager.activeTab === 0 }
                PinnedTab   { anchors.fill: parent; visible: ClipboardManager.activeTab === 1 }
                NoteCardsTab{ anchors.fill: parent; visible: ClipboardManager.activeTab === 2 }
            }
        }
    }
}
