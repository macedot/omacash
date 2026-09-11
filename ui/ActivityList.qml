import QtQuick
import QtQuick.Layouts
import qs.Commons
import "Format.js" as Format

ColumnLayout {
  id: root
  property string title: ""
  property var rows: []
  property string currency: "USD"
  property bool bills: false
  spacing: Style.space(6)

  Text {
    text: root.title
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1.2
    font.bold: true
  }

  Repeater {
    model: root.rows
    delegate: RowLayout {
      required property var modelData
      Layout.fillWidth: true
      spacing: Style.space(8)
      Text {
        text: Format.prettyDate(modelData.iso)
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        Layout.preferredWidth: Style.space(52)
      }
      Text {
        text: Format.categoryGlyph(modelData.category || modelData.name)
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }
      Text {
        text: modelData.name
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
      Text {
        text: Format.signedMoney(modelData.value, root.currency)
        color: modelData.value < 0 ? Color.urgent : Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }
    }
  }

  Text {
    visible: !root.rows || root.rows.length === 0
    text: root.bills ? "No upcoming bills" : "No recent activity"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
}
