pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.config

// Fullscreen overlay PanelWindow that shows a context menu at cursor position.
// Usage: set targetItem and menuItems, then call show(screenX, screenY).
PanelWindow {
    id: root

    required property ShellScreen screen

    // List of { label: string, action: string, icon: string (optional) }
    property var menuItems: []

    signal actionSelected(string action)
    signal dismissed

    // Internal position
    property real menuX: 0
    property real menuY: 0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "caelestia-clipboard-ctx-" + (screen?.name ?? "unknown")
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // ── Public API ────────────────────────────────────────────────────────────

    function show(items, cursorX, cursorY) {
        root.menuItems = items || [];
        visible = true;
        _reposition(cursorX, cursorY);
        // Re-run after a frame so implicitHeight is settled
        Qt.callLater(() => _reposition(cursorX, cursorY));
    }

    function close() {
        visible = false;
        menuItems = [];
    }

    function _reposition(cx, cy) {
        const sw = screen?.width  ?? 1920;
        const sh = screen?.height ?? 1080;
        const mw = menuBox.implicitWidth  || 200;
        const mh = menuBox.implicitHeight || 80;
        const pad = Appearance.padding.normal;
        menuX = Math.max(pad, Math.min(sw - mw - pad, cx));
        menuY = Math.max(pad, Math.min(sh - mh - pad, cy));
    }

    // ── Outside-click dismiss ─────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 0
        onClicked: {
            root.dismissed();
            root.close();
        }
    }

    Keys.onEscapePressed: {
        root.dismissed();
        root.close();
    }

    // ── Menu box ──────────────────────────────────────────────────────────────
    Rectangle {
        id: menuBox
        x: root.menuX
        y: root.menuY
        z: 1

        implicitWidth:  Math.min(240, Math.max(160, menuCol.implicitWidth  + Appearance.padding.normal * 2))
        implicitHeight: Math.min(360, Math.max(48,  menuCol.implicitHeight + Appearance.padding.normal * 2))

        color:  Colours.palette.m3surfaceContainer
        radius: Config.border.rounding
        border.width: 1
        border.color: Qt.rgba(
            Colours.palette.m3outline.r,
            Colours.palette.m3outline.g,
            Colours.palette.m3outline.b,
            0.15
        )

        // Subtle drop shadow layer
        Rectangle {
            anchors.fill: parent
            anchors.topMargin:    3
            anchors.leftMargin:   2
            anchors.rightMargin: -2
            anchors.bottomMargin:-3
            radius: parent.radius
            color: Colours.palette.m3shadow
            opacity: 0.12
            z: -1
        }

        // Appear animation
        scale: root.visible ? 1.0 : 0.92
        opacity: root.visible ? 1.0 : 0.0
        transformOrigin: Item.TopLeft

        Behavior on scale   { CAnim {} }
        Behavior on opacity { CAnim {} }

        Flickable {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            clip: true
            contentHeight: menuCol.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
                id: menuCol
                width: parent.width
                spacing: Appearance.spacing.small

                Repeater {
                    model: root.menuItems

                    delegate: Rectangle {
                        id: menuEntry
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: entryRow.implicitHeight + Appearance.padding.small * 2
                        radius: Config.border.rounding - 2
                        color: entryState.containsMouse
                               ? Colours.palette.m3surfaceContainerHighest
                               : "transparent"

                        Behavior on color { CAnim {} }

                        // Separator above certain actions (e.g. destructive ones)
                        Rectangle {
                            visible: menuEntry.index > 0 && (menuEntry.modelData.separator ?? false)
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Appearance.spacing.small / 2
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Colours.palette.m3outlineVariant
                            opacity: 0.4
                        }

                        RowLayout {
                            id: entryRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Appearance.padding.small
                            anchors.rightMargin: Appearance.padding.small
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                visible: (menuEntry.modelData.icon ?? "").length > 0
                                icon: menuEntry.modelData.icon ?? ""
                                size: 15
                                color: menuEntry.modelData.destructive
                                       ? Colours.palette.m3error
                                       : Colours.palette.m3onSurface
                            }

                            Text {
                                Layout.fillWidth: true
                                text: menuEntry.modelData.label ?? ""
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: menuEntry.modelData.destructive
                                       ? Colours.palette.m3error
                                       : Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }
                        }

                        StateLayer {
                            id: entryState
                            radius: menuEntry.radius
                            onClicked: {
                                root.actionSelected(menuEntry.modelData.action ?? "");
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onDestruction: close()
}
