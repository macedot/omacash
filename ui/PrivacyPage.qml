import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.Commons
import qs.Ui

Item {
  id: root
  property var session

  FileDialog {
    id: importDialog
    title: "Import CSV"
    nameFilters: ["CSV files (*.csv)", "All files (*)"]
    fileMode: FileDialog.OpenFile
    onAccepted: {
      var path = String(selectedFile).replace(/^file:\/\//, "")
      session.importFromPath(path)
    }
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(14)

    Text {
      text: "DATA & PRIVACY"
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
      font.letterSpacing: 1.5
      font.bold: true
    }

    Text {
      text: "Omacash never opens a network connection. Events, settings, and UI restore files stay on this machine."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    Repeater {
      model: [
        { label: "Config", path: session.store.configPath },
        { label: "Events", path: session.store.eventsPath },
        { label: "State", path: session.store.statePath }
      ]
      delegate: ColumnLayout {
        required property var modelData
        spacing: 2
        Layout.fillWidth: true
        Text {
          text: modelData.label
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
        }
        Text {
          text: modelData.path
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WrapAnywhere
          Layout.fillWidth: true
        }
      }
    }

    Text {
      text: "CSV files default to " + session.downloadsDir
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WrapAnywhere
      Layout.fillWidth: true
    }

    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true
      Button { text: "Import from Downloads"; bordered: true; onClicked: session.importFromDownloads() }
      Button { text: "Choose file…"; bordered: true; onClicked: importDialog.open() }
    }
    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true
      Button { text: "Export events"; bordered: true; onClicked: session.exportEventsToDownloads() }
      Button { text: "Export results"; bordered: true; onClicked: session.exportResultsToDownloads() }
    }

    Text {
      visible: session.csvNotice !== ""
      text: session.csvNotice
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: wipeCol.implicitHeight + Style.space(20)
      color: "transparent"
      border.width: 1
      border.color: Color.urgent
      ColumnLayout {
        id: wipeCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.space(12)
        spacing: Style.space(8)
        Text {
          text: "Wipe all local data"
          color: Color.urgent
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.bold: true
        }
        Text {
          text: "Deletes events, config, and remembered UI state on disk. The plugin stays installed."
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
        Button {
          text: session.confirmWipe ? "Confirm wipe" : "Wipe data"
          bordered: true
          foreground: Color.urgent
          onClicked: {
            if (session.confirmWipe) session.wipe()
            else session.confirmWipe = true
          }
        }
      }
    }

    Item { Layout.fillHeight: true }
  }
}
