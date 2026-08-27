pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Kirigami.Units.gridUnit * 18
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 15

    readonly property real batteryPercentValue: Number(root.info.batteryPercent)
    readonly property real clampedBatteryPercent: Number.isFinite(batteryPercentValue) ? Math.max(0, Math.min(100, batteryPercentValue)) : 0
    readonly property color batteryFillColor: Qt.hsva((clampedBatteryPercent / 100) * 0.33, 0.78, 0.92, 1)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        // Top Header: UPS Info (Left) + Battery Card (Right)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            spacing: Kirigami.Units.smallSpacing

            // Left: UPS Device Info
            QQC2.Frame {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.mediumSpacing

                    Kirigami.Icon {
                        source: "battery-ups"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.info.ok ? root.info.model : i18n("UPS Monitor")
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.statusLine
                            color: root.statusColor
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.info.ok ? root.info.upsName : root.lastError
                            opacity: 0.7
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // Right: Battery Level Card
            QQC2.Frame {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: i18n("Battery Charge")
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        Kirigami.Icon {
                            source: root.iconName
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.percentText
                        color: root.statusColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 8
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Alarm Banner (if active)
        QQC2.Frame {
            visible: root.hasAlarm
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 2
                QQC2.Label { text: i18n("Alarm"); opacity: 0.7 }
                QQC2.Label { text: root.info.alarm; color: Kirigami.Theme.negativeTextColor; font.bold: true; wrapMode: Text.WordWrap }
            }
        }

        // 2-Column Responsive Metrics Grid
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            // Grid Input
            QQC2.Frame {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Grid Input Voltage"); opacity: 0.7; elide: Text.ElideRight }
                    QQC2.Label { Layout.fillWidth: true; text: root.inputVoltageText; font.bold: true; horizontalAlignment: Text.AlignRight }
                }
            }

            // Output Voltage
            QQC2.Frame {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Output Voltage (AVR)"); opacity: 0.7; elide: Text.ElideRight }
                    QQC2.Label { Layout.fillWidth: true; text: root.outputVoltageText; font.bold: true; horizontalAlignment: Text.AlignRight }
                }
            }

            // Load & Power
            QQC2.Frame {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Load / Power"); opacity: 0.7; elide: Text.ElideRight }
                    QQC2.Label { Layout.fillWidth: true; text: root.loadText + "  (" + root.powerText + ")"; font.bold: true; horizontalAlignment: Text.AlignRight }
                }
            }

            // Battery Voltage
            QQC2.Frame {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Battery Pack Voltage"); opacity: 0.7; elide: Text.ElideRight }
                    QQC2.Label { Layout.fillWidth: true; text: root.batteryVoltageText; font.bold: true; horizontalAlignment: Text.AlignRight }
                }
            }

            // Frequency
            QQC2.Frame {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    QQC2.Label { Layout.fillWidth: true; text: i18n("AC Frequency"); opacity: 0.7; elide: Text.ElideRight }
                    QQC2.Label { Layout.fillWidth: true; text: root.frequencyText; font.bold: true; horizontalAlignment: Text.AlignRight }
                }
            }

            // Estimated Runtime
            QQC2.Frame {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Estimated Runtime"); opacity: 0.7; elide: Text.ElideRight }
                    QQC2.Label { Layout.fillWidth: true; text: root.runtimeTextValue; font.bold: true; horizontalAlignment: Text.AlignRight }
                }
            }
        }

        // Bottom Footer: Last Power Loss + Refresh Countdown
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Frame {
                Layout.fillWidth: true
                RowLayout {
                    anchors.fill: parent
                    QQC2.Label { text: i18n("Last power loss: "); opacity: 0.7 }
                    QQC2.Label { Layout.fillWidth: true; text: root.lastPowerLossText; font.bold: true; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight }
                }
            }

            Item {
                id: refreshIndicator
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                opacity: 0.6

                Canvas {
                    id: refreshCanvas
                    anchors.fill: parent
                    antialiasing: true

                    onPaint: {
                        const ctx = getContext("2d")
                        const w = width
                        const h = height
                        const lineWidth = Math.max(1.5, Math.min(w, h) * 0.09)
                        const radius = (Math.min(w, h) - lineWidth) / 2
                        const cx = w / 2
                        const cy = h / 2
                        const start = -Math.PI / 2
                        const end = start + (Math.PI * 2 * root.countdownProgress)

                        ctx.reset()
                        ctx.clearRect(0, 0, w, h)

                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                        ctx.lineWidth = lineWidth
                        ctx.stroke()

                        if (root.countdownProgress > 0) {
                            ctx.beginPath()
                            ctx.arc(cx, cy, radius, start, end, false)
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.28)
                            ctx.lineWidth = lineWidth
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }

                    Connections {
                        target: root
                        function onCountdownProgressChanged() {
                            refreshCanvas.requestPaint()
                        }
                    }
                }

                QQC2.Label {
                    anchors.centerIn: parent
                    text: String(root.countdownSecondsRemaining)
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.62)
                }
            }
        }
    }
}
