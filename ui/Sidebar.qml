import QtQuick
import QtQuick.Layouts
import qs.Commons
import "Format.js" as Format

Rectangle {
  id: root
  property string current: "dashboard"
  property var session: null
  signal pageChosen(string id)

  color: "transparent"
  implicitWidth: Style.space(168)

  readonly property var items: [
    { id: "dashboard", label: "Dashboard", enabled: true },
    { id: "accounts", label: "Accounts", enabled: false },
    { id: "transactions", label: "Transactions", enabled: false },
    { id: "budget", label: "Budget", enabled: false },
    { id: "events", label: "Events", enabled: true },
    { id: "bills", label: "Bills", enabled: false },
    { id: "reports", label: "Reports", enabled: false },
    { id: "settings", label: "Settings", enabled: true },
    { id: "privacy", label: "Data & Privacy", enabled: true }
  ]

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.space(12)
    spacing: Style.space(2)

    Repeater {
      model: root.items
      delegate: Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: Style.space(28)
        color: modelData.id === root.current ? Qt.alpha(Color.accent, 0.18) : (area.containsMouse && modelData.enabled ? Qt.alpha(Color.foreground, 0.06) : "transparent")
        border.width: modelData.id === root.current ? 1 : 0
        border.color: Color.accent
        opacity: modelData.enabled ? 1 : 0.4

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.space(8)
          anchors.rightMargin: Style.space(8)
          spacing: Style.space(8)
          Text {
            text: Format.navGlyph(modelData.id)
            color: modelData.id === root.current ? Color.accent : Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }
          Text {
            text: modelData.label
            color: modelData.id === root.current ? Color.accent : Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            Layout.fillWidth: true
          }
        }
        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          enabled: modelData.enabled
          onClicked: root.pageChosen(modelData.id)
        }
      }
    }

    Item { Layout.fillHeight: true }

    Text {
      text: "Your money.\nYour device.\nAlways private."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
}
