import QtQuick
import QtQuick.Layouts
import qs.Commons
import "Format.js" as Format

GridLayout {
  id: root
  property var rows: []
  property string currency: "USD"
  columns: 3
  rowSpacing: Style.space(10)
  columnSpacing: Style.space(10)

  Repeater {
    model: root.rows
    delegate: Rectangle {
      required property var modelData
      Layout.fillWidth: true
      Layout.preferredHeight: Style.space(72)
      color: "transparent"
      border.width: 1
      border.color: Qt.alpha(Color.accent, 0.28)

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(10)
        spacing: Style.space(4)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)
          Text {
            text: Format.categoryGlyph(modelData.name)
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
        }
        Text {
          text: Format.money(modelData.spent, root.currency) + (modelData.budget ? " / " + Format.money(modelData.budget, root.currency) : "")
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Rectangle {
          Layout.fillWidth: true
          height: 6
          color: Qt.alpha(Color.foreground, 0.12)
          Rectangle {
            width: parent.width * Math.min(1, modelData.budget > 0 ? modelData.spent / modelData.budget : 0)
            height: parent.height
            color: (modelData.budget > 0 && modelData.spent / modelData.budget > 1) ? Color.urgent : Color.accent
          }
        }
      }
    }
  }

  Text {
    visible: !root.rows || root.rows.length === 0
    text: "No categorized expenses yet"
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    Layout.columnSpan: 3
  }
}
