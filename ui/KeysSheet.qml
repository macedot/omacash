import QtQuick
import QtQuick.Layouts
import qs.Commons
import "Keys.js" as KeyMap

Rectangle {
  id: root
  property var bindings: ({})
  visible: false
  color: Qt.alpha(Color.background, 0.96)
  border.width: 1
  border.color: Color.accent

  function show() { visible = true }
  function close() { visible = false }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.space(16)
    spacing: Style.space(8)

    Text {
      text: "KEYS"
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
      font.letterSpacing: 1.5
      font.bold: true
    }

    Repeater {
      model: KeyMap.SHEET
      delegate: RowLayout {
        required property var modelData
        Layout.fillWidth: true
        Text {
          text: modelData.label
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.fillWidth: true
        }
        Text {
          text: (root.bindings[modelData.id] || []).map(KeyMap.pretty).join("  ")
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }

    Text {
      text: "Esc closes this sheet"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }
}
