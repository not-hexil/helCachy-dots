pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.images
import qs.components.containers
import qs.services
import qs.config

Item {
    id: root

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.smaller

        RowLayout {
            Layout.leftMargin: Appearance.padding.large
            Layout.rightMargin: Appearance.padding.large
            Layout.fillWidth: true

            Column {
                spacing: Appearance.spacing.small / 2

                StyledText {
                    text: qsTr("Wallpaper")
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 600
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: qsTr("Select a wallpaper from your library")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: Wallpapers.list.length + qsTr(" wallpapers")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.bottomMargin: Appearance.padding.normal
            implicitHeight: 400

            radius: Appearance.rounding.large * 2
            color: Colours.tPalette.m3surfaceContainer

            GridView {
                id: grid

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                readonly property int columns: 4

                cellWidth: Math.floor(width / columns)
                cellHeight: Math.floor(cellWidth * 0.6)
                clip: true
                interactive: true

                model: Wallpapers.list

                delegate: Item {
                    id: wallpaperDelegate

                    required property var modelData
                    readonly property bool isCurrent: modelData.path === Wallpapers.actualCurrent

                    width: grid.cellWidth
                    height: grid.cellHeight

                    StyledClippingRect {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.smaller

                        radius: Appearance.rounding.large
                        color: Colours.tPalette.m3surfaceContainer
                        border.width: wallpaperDelegate.isCurrent ? 2 : 0
                        border.color: Colours.palette.m3primary

                        CachingImage {
                            anchors.fill: parent
                            path: wallpaperDelegate.modelData.path
                            fillMode: Image.PreserveAspectCrop
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter
                        }

                        StyledRect {
                            visible: wallpaperDelegate.isCurrent
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: Appearance.padding.small
                            implicitWidth: activeIcon.implicitWidth + Appearance.padding.small * 2
                            implicitHeight: implicitWidth
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3primary

                            MaterialIcon {
                                id: activeIcon
                                anchors.centerIn: parent
                                text: "check"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onPrimary
                            }
                        }

                        StateLayer {
                            function onClicked(): void {
                                Wallpapers.setWallpaper(wallpaperDelegate.modelData.path)
                            }
                            radius: parent.radius
                            color: Colours.palette.m3onSurface
                        }
                    }
                }
            }
        }
    }
}
