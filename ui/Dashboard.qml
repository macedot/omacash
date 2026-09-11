import QtQuick
import QtQuick.Layouts
import qs.Commons
import "Format.js" as Format

Item {
  id: root
  property var session

  readonly property string monthLabel: Format.monthName(session.thisMonth).toUpperCase()
  readonly property real spendRatio: session.monthlySpendCap ? session.monthSpend / session.monthlySpendCap : 0

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(12)

    RowLayout {
      Layout.fillWidth: true
      ColumnLayout {
        spacing: 2
        Text {
          text: "OMACASH"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.letterSpacing: 2
          font.bold: true
        }
        Text {
          text: "Local-first personal finance  //  Plan well. Live freer."
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
      Item { Layout.fillWidth: true }
      Rectangle {
        implicitWidth: chip.implicitWidth + Style.space(16)
        implicitHeight: Style.space(36)
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Color.accent, 0.35)
        RowLayout {
          id: chip
          anchors.centerIn: parent
          spacing: Style.space(8)
          Rectangle { width: 7; height: 7; radius: 4; color: "#7fd97f" }
          Column {
            Text {
              text: "All data stored locally"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
            Text {
              text: "No cloud. No tracking. Just you."
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: Style.space(110)
      spacing: Style.space(10)

      KpiCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
        kicker: "TOTAL CASH ON HAND"
        value: Format.money(session.todayBalance, session.currency)
        footnote: Format.signedMoney(session.monthDelta, session.currency) + " this month"
        warn: session.todayBalance < 0
        spark: session.spark
      }

      KpiCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
        kicker: "SPENDING (" + root.monthLabel.slice(0, 3) + ")"
        value: Format.money(session.monthSpend, session.currency)
        footnote: session.monthlySpendCap
          ? Math.round(root.spendRatio * 100) + "% of " + Format.money(session.monthlySpendCap, session.currency)
          : "Set a monthly cap in Settings"
        Rectangle {
          visible: session.monthlySpendCap !== null && session.monthlySpendCap !== undefined
          Layout.fillWidth: true
          height: 6
          color: Qt.alpha(Color.foreground, 0.12)
          Rectangle {
            width: parent.width * Math.min(1, root.spendRatio)
            height: parent.height
            color: root.spendRatio >= 1 ? Color.urgent : Color.accent
          }
        }
      }

      KpiCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
        kicker: "SAVINGS RATE"
        value: Format.percent(session.savings)
        footnote: Format.percent(session.savingsDelta) + " from last month"
        spark: session.savingsBars
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: Style.space(180)
      spacing: Style.space(10)

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 3
        Layout.minimumHeight: Style.space(160)
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Color.accent, 0.28)
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.space(12)
          spacing: Style.space(8)
          Text {
            text: "BUDGET BY CATEGORY"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1.2
            font.bold: true
          }
          CategoryGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            rows: session.categories
            currency: session.currency
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 2
        Layout.minimumHeight: Style.space(160)
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Color.accent, 0.28)
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.space(12)
          spacing: Style.space(8)
          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "CASHFLOW"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1.2
              font.bold: true
            }
            Item { Layout.fillWidth: true }
            Repeater {
              model: [
                { id: "3m", label: "3M" },
                { id: "6m", label: "6M" },
                { id: "1y", label: "1Y" }
              ]
              delegate: Text {
                required property var modelData
                text: modelData.label
                color: session.range === modelData.id ? Color.accent : Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: session.range === modelData.id
                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -4
                  onClicked: session.setRange(modelData.id)
                }
              }
            }
          }
          CashflowChart {
            Layout.fillWidth: true
            Layout.fillHeight: true
            series: session.monthly
          }
          RowLayout {
            spacing: Style.space(10)
            Repeater {
              model: [
                { label: "Income", color: Color.accent },
                { label: "Expenses", color: Color.urgent },
                { label: "Net", color: Color.muted }
              ]
              delegate: RowLayout {
                required property var modelData
                spacing: 4
                Rectangle { width: 8; height: 8; color: modelData.color }
                Text {
                  text: modelData.label
                  color: Color.muted
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: Style.space(150)
      Layout.maximumHeight: Style.space(180)
      spacing: Style.space(10)

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Color.accent, 0.28)
        ActivityList {
          anchors.fill: parent
          anchors.margins: Style.space(12)
          title: "RECENT ACTIVITY  (from recurring events)"
          rows: session.recent
          currency: session.currency
        }
      }
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Color.accent, 0.28)
        ActivityList {
          anchors.fill: parent
          anchors.margins: Style.space(12)
          title: "UPCOMING BILLS"
          rows: session.upcoming
          currency: session.currency
          bills: true
        }
      }
    }
  }
}
