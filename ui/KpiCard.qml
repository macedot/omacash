import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root
  property string kicker: ""
  property string value: ""
  property string footnote: ""
  property color valueColor: Color.foreground
  property bool warn: false
  property var spark: []

  color: "transparent"
  border.width: 1
  border.color: Qt.alpha(Color.accent, 0.35)
  implicitHeight: col.implicitHeight + Style.space(24)
  implicitWidth: 180
  clip: true

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: Style.space(14)
    spacing: Style.space(6)

    Text {
      text: root.kicker
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1.2
      font.bold: true
    }
    Text {
      text: root.value
      color: root.warn ? Color.urgent : root.valueColor
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
    Text {
      visible: root.footnote !== ""
      text: root.footnote
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
    Sparkline {
      visible: !!(root.spark && root.spark.length > 1)
      Layout.fillWidth: true
      Layout.preferredHeight: 28
      points: root.spark
      stroke: Color.accent
    }
  }
}
