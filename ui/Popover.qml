import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Format.js" as Format

Item {
  id: root
  required property var session
  signal closeRequested()
  signal expandRequested()

  Keys.onPressed: function (event) {
    if (event.key === Qt.Key_Escape) {
      root.closeRequested()
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.expandRequested()
      event.accepted = true
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 4
    spacing: Style.space(8)

    RowLayout {
      Layout.fillWidth: true
      Text {
        text: "OMACASH"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1.5
        font.bold: true
      }
      Item { Layout.fillWidth: true }
      Rectangle {
        width: 6; height: 6; radius: 3
        color: "#7fd97f"
        Layout.alignment: Qt.AlignVCenter
      }
      Text {
        text: "local"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    Text {
      text: "Cash on hand"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
    Text {
      text: Format.money(session.todayBalance, session.currency)
      color: session.todayBalance < 0 ? Color.urgent : Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.display
      font.bold: true
    }

    Sparkline {
      Layout.fillWidth: true
      Layout.preferredHeight: 36
      points: session.spark
      stroke: Color.accent
    }

    Text {
      text: "This month  " + Format.signedMoney(session.monthNet, session.currency)
      color: session.monthNet < 0 ? Color.urgent : Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }

    Repeater {
      model: session.upcoming
      delegate: RowLayout {
        required property var modelData
        Layout.fillWidth: true
        Text {
          text: Format.prettyDate(modelData.iso)
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Layout.preferredWidth: 48
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
          text: Format.money(modelData.value, session.currency)
          color: Color.urgent
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }

    Item { Layout.fillHeight: true }

    Text {
      text: session.events.length === 0 ? "No events yet — press Enter to add" : "Enter  expand   Esc  close"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  MouseArea {
    anchors.fill: parent
    z: -1
    onClicked: root.expandRequested()
  }
}
