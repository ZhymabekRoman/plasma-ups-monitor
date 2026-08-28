pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
    id: compactRoot

    readonly property bool isVertical: [
        PlasmaCore.Types.LeftEdge,
        PlasmaCore.Types.RightEdge
    ].includes(root.Plasmoid.location) || root.Plasmoid.formFactor === PlasmaCore.Types.Vertical || width < 60

    implicitWidth: isVertical ? (col.implicitWidth + Kirigami.Units.smallSpacing * 2) : (row.implicitWidth + Kirigami.Units.smallSpacing * 2)
    implicitHeight: isVertical ? (col.implicitHeight + Kirigami.Units.smallSpacing * 2) : (row.implicitHeight + Kirigami.Units.smallSpacing * 2)

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.expanded = !root.expanded
        }
    }

    // Horizontal layout (for horizontal panels)
    RowLayout {
        id: row
        visible: !compactRoot.isVertical
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: root.iconName
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            opacity: root.info.onBattery ? 0.75 : 1

            SequentialAnimation on opacity {
                running: Boolean(root.info && root.info.onBattery)
                loops: Animation.Infinite
                OpacityAnimator { from: 1; to: 0.45; duration: 700 }
                OpacityAnimator { from: 0.45; to: 1; duration: 700 }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            QQC2.Label {
                Layout.fillWidth: true
                font.bold: true
                horizontalAlignment: Text.AlignLeft
                text: root.info.ok ? root.percentText : i18n("UPS")
                color: root.statusColor
                elide: Text.ElideRight
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: root.compactSecondaryText
                opacity: 0.75
                font.pointSize: Math.max(8, Kirigami.Theme.defaultFont.pointSize - 1)
                elide: Text.ElideRight
            }
        }
    }

    // Vertical layout (for vertical panels)
    ColumnLayout {
        id: col
        visible: compactRoot.isVertical
        anchors.centerIn: parent
        spacing: 1

        Kirigami.Icon {
            source: root.iconName
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            opacity: (root.info && root.info.onBattery) ? 0.75 : 1

            SequentialAnimation on opacity {
                running: Boolean(root.info && root.info.onBattery)
                loops: Animation.Infinite
                OpacityAnimator { from: 1; to: 0.45; duration: 700 }
                OpacityAnimator { from: 0.45; to: 1; duration: 700 }
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            font.bold: true
            font.pointSize: Math.max(7, Kirigami.Theme.defaultFont.pointSize - 2)
            horizontalAlignment: Text.AlignHCenter
            text: root.info.ok ? root.percentText : i18n("UPS")
            color: root.statusColor
            elide: Text.ElideRight
        }
    }
}


