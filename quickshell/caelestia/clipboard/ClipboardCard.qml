pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

Rectangle {
    id: root

    // ── Required inputs ───────────────────────────────────────────────────────
    required property var clipboardItem   // { id, preview, isImage, mime }
    required property bool isPinned

    // ── Optional callbacks ────────────────────────────────────────────────────
    signal copyClicked
    signal deleteClicked
    signal pinClicked
    signal unpinClicked
    signal rightClicked(real mouseX, real mouseY)

    // ── Type detection ────────────────────────────────────────────────────────
    readonly property string itemType: ClipboardService.getItemType(clipboardItem)

    readonly property bool isImage:  itemType === "Image"
    readonly property bool isColor:  itemType === "Color"
    readonly property bool isLink:   itemType === "Link"
    readonly property bool isCode:   itemType === "Code"
    readonly property bool isEmoji:  itemType === "Emoji"
    readonly property bool isFile:   itemType === "File"
    readonly property bool isText:   itemType === "Text"

    readonly property string preview: clipboardItem?.preview ?? ""

    readonly property string colorValue: {
        if (!isColor || !preview) return "";
        const t = preview.trim();
        if (/^#[A-Fa-f0-9]{3,6}$/.test(t)) return t;
        if (/^[A-Fa-f0-9]{6}$/.test(t))    return "#" + t;
        return t;
    }

    // ── Type → icon name (Material Symbols) ──────────────────────────────────
    readonly property string typeIcon: {
        switch (itemType) {
        case "Image": return "image";
        case "Color": return "palette";
        case "Link":  return "link";
        case "Code":  return "code";
        case "Emoji": return "sentiment_satisfied";
        case "File":  return "description";
        default:      return "format_align_left";
        }
    }

    // ── Type → accent color ───────────────────────────────────────────────────
    readonly property color accentColor: {
        switch (itemType) {
        case "Link":  return Colours.palette.m3primaryContainer;
        case "Code":  return Colours.palette.m3secondaryContainer;
        case "Color": return Colours.palette.m3tertiaryContainer;
        case "Image": return Colours.palette.m3surfaceContainer;
        default:      return Colours.palette.m3surfaceContainerHigh;
        }
    }
    readonly property color accentFg: Colours.palette.m3onSurface

    // ── Geometry ──────────────────────────────────────────────────────────────
    readonly property int headerH: 32
    readonly property int bodyPad: Appearance.padding.small
    readonly property int bodyW:   root.width - bodyPad * 2
    readonly property int contentH: isImage ? 140
                                  : Math.max(22, Math.ceil(measure.contentHeight))
    readonly property int totalH:  headerH + 1 + bodyPad * 2 + contentH

    width:  220
    height: Math.min(360, totalH)

    radius: Config.border.rounding
    color:  stateLayer.containsMouse
            ? Qt.lighter(accentColor, 1.12)
            : accentColor

    Behavior on color {
        CAnim {}
    }

    // Hover/focus outline
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: stateLayer.containsMouse ? 2 : 0
        border.color: Colours.palette.m3primary
        z: 10

        Behavior on border.width {
            CAnim {}
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header bar
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerH

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.padding.small
                anchors.rightMargin: Appearance.padding.small
                spacing: Appearance.spacing.small

                MaterialIcon {
                    icon: root.typeIcon
                    size: 14
                    color: root.accentFg
                }

                Text {
                    text: root.itemType
                    color: root.accentFg
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                // Pin / Unpin button
                Item {
                    width: 22
                    height: 22
                    visible: true

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: root.isPinned ? "keep_off" : "keep"
                        size: 14
                        color: root.accentFg
                    }

                    StateLayer {
                        radius: Appearance.rounding.full
                        onClicked: root.isPinned ? root.unpinClicked() : root.pinClicked()
                    }
                }

                // Delete button
                Item {
                    width: 22
                    height: 22

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: "delete"
                        size: 14
                        color: root.accentFg
                    }

                    StateLayer {
                        radius: Appearance.rounding.full
                        onClicked: root.deleteClicked()
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            height: 1
            color: Colours.palette.m3outlineVariant
            opacity: 0.5
        }

        // Body
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: root.bodyPad
            clip: true

            // Color swatch
            Rectangle {
                visible: root.isColor
                anchors.fill: parent
                radius: Config.border.rounding - root.bodyPad
                color: root.colorValue || "transparent"
                border.width: 1
                border.color: Colours.palette.m3outline

                // Color code pill
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    height: 20
                    width: pillLabel.implicitWidth + 14
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.6)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    visible: root.colorValue.length > 0

                    Text {
                        id: pillLabel
                        anchors.centerIn: parent
                        text: root.colorValue.toUpperCase()
                        font.pixelSize: 10
                        font.bold: true
                        color: "#ffffff"
                    }
                }
            }

            // Text / link / code / emoji / file preview
            Text {
                id: previewText
                visible: !root.isColor && !root.isImage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                text: root.preview
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 8
                color: root.accentFg
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: root.isCode ? Appearance.font.family.mono
                                         : Appearance.font.family.sans
            }

            // Hidden measure element — width bound to bodyW to avoid feedback loops
            Text {
                id: measure
                visible: false
                text: root.preview
                wrapMode: Text.Wrap
                font.pixelSize: previewText.font.pixelSize
                font.family: previewText.font.family
                width: root.bodyW
            }

            // Image display
            Rectangle {
                visible: root.isImage
                anchors.fill: parent
                radius: Config.border.rounding - root.bodyPad
                color: "transparent"
                clip: true

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: {
                        const _rev = ClipboardService.imageCacheRevision;
                        return ClipboardService.imageCache[root.clipboardItem?.id ?? ""] ?? "";
                    }
                }

                Component.onCompleted: {
                    const id = root.clipboardItem?.id;
                    if (id && root.isImage)
                        ClipboardService.decodeImage(id);
                }
            }
        }
    }

    // ── Interaction ───────────────────────────────────────────────────────────
    StateLayer {
        id: stateLayer
        showHoverBackground: false   // card handles its own color shift
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton) {
                root.rightClicked(event.x, event.y);
            } else {
                root.copyClicked();
            }
        }
    }
}
