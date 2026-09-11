import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Item {
  id: root
  property var session

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(14)

    Text {
      text: "SETTINGS"
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
      font.letterSpacing: 1.5
      font.bold: true
    }

    GridLayout {
      columns: 2
      columnSpacing: Style.space(16)
      rowSpacing: Style.space(12)
      Layout.fillWidth: true

      Text { text: "Currency"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall }
      Dropdown {
        value: session.currency
        options: ["USD", "EUR", "GBP", "BRL"]
        showLabel: false
        onChanged: function (v) { session.setCurrency(v) }
      }

      Text { text: "Period"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall }
      Dropdown {
        value: session.period
        options: [
          { value: "1m", label: "1 month" },
          { value: "3m", label: "3 months" },
          { value: "6m", label: "6 months" },
          { value: "1y", label: "1 year" }
        ]
        showLabel: false
        onChanged: function (v) { session.setPeriod(v) }
      }

      Text { text: "Initial balance"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall }
      TextField {
        text: String(session.initialBalance)
        Layout.preferredWidth: Style.space(160)
        onEditingFinished: session.setInitialBalance(text)
      }

      Text { text: "Monthly spend cap"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall }
      TextField {
        placeholderText: "optional"
        text: session.monthlySpendCap === null || session.monthlySpendCap === undefined ? "" : String(session.monthlySpendCap)
        Layout.preferredWidth: Style.space(160)
        onEditingFinished: session.setSpendCap(text)
      }
    }

    Text {
      text: "Keys are listed on the ? sheet. Bindings live in ~/.config/omacash/config.toml under [keys]."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    Item { Layout.fillHeight: true }
  }
}
