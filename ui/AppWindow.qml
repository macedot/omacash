import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Format.js" as Format
import "Keys.js" as KeyMap

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool closingFromHost: false
  property bool pendingG: false
  property string clockText: ""

  function open(payloadJson) {
    closingFromHost = false
    window.visible = true
    Qt.callLater(function () { keyCatcher.forceActiveFocus() })
  }

  function close() {
    closingFromHost = true
    window.visible = false
    closingFromHost = false
  }

  function requestClose() {
    if (shell && typeof shell.hide === "function") shell.hide("com.omacash.cashflow")
    else window.visible = false
  }

  function run(action) {
    if (action === "dashboard") session.setPage("dashboard")
    else if (action === "events") session.setPage("events")
    else if (action === "settings") session.setPage("settings")
    else if (action === "privacy") session.setPage("privacy")
    else if (action === "new_event") { session.setPage("events"); eventsPage.openNew() }
    else if (action === "delete_event") eventsPage.removeSelected()
    else if (action === "range_3m") session.setRange("3m")
    else if (action === "range_6m") session.setRange("6m")
    else if (action === "range_1y") session.setRange("1y")
    else if (action === "cycle_currency") session.cycleCurrency()
    else if (action === "export_csv") session.exportEventsToDownloads()
    else if (action === "export_results") session.exportResultsToDownloads()
    else if (action === "import_csv") session.importFromDownloads()
    else if (action === "help") { if (sheet.visible) sheet.close(); else sheet.show() }
    else if (action === "close") {
      if (sheet.visible) sheet.close()
      else if (eventsPage.formOpen) eventsPage.formOpen = false
      else requestClose()
    }
  }

  Session { id: session }

  Timer {
    interval: 1000
    running: window.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.clockText = Format.clockLabel(new Date())
  }

  Timer {
    id: gTimer
    interval: 700
    onTriggered: root.pendingG = false
  }

  FloatingWindow {
    id: window
    title: "Omacash"
    color: Color.background
    implicitWidth: 1100
    implicitHeight: 720
    minimumSize: Qt.size(720, 520)

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide("com.omacash.cashflow")
    }

    FocusScope {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
          root.run("close")
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Question || (event.key === Qt.Key_Slash && event.modifiers & Qt.ShiftModifier)) {
          root.run("help")
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_G && !(event.modifiers & Qt.ControlModifier)) {
          root.pendingG = true
          gTimer.restart()
          event.accepted = true
          return
        }
        if (root.pendingG) {
          root.pendingG = false
          gTimer.stop()
          if (event.key === Qt.Key_D) root.run("dashboard")
          else if (event.key === Qt.Key_E) root.run("events")
          else if (event.key === Qt.Key_S) root.run("settings")
          else if (event.key === Qt.Key_P) root.run("privacy")
          event.accepted = true
          return
        }
        if (eventsPage.formOpen) return
        if (event.key === Qt.Key_N) { root.run("new_event"); event.accepted = true }
        else if (event.key === Qt.Key_X || event.key === Qt.Key_Delete) { root.run("delete_event"); event.accepted = true }
        else if (event.key === Qt.Key_3) { root.run("range_3m"); event.accepted = true }
        else if (event.key === Qt.Key_6) { root.run("range_6m"); event.accepted = true }
        else if (event.key === Qt.Key_Y) { root.run("range_1y"); event.accepted = true }
        else if (event.key === Qt.Key_C) { root.run("cycle_currency"); event.accepted = true }
        else if (event.key === Qt.Key_I) { root.run("import_csv"); event.accepted = true }
        else if (event.key === Qt.Key_E) { root.run("export_csv"); event.accepted = true }
        else if (event.key === Qt.Key_R) { root.run("export_results"); event.accepted = true }
        else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
          eventsPage.selected = Math.min(eventsPage.selected + 1, Math.max(0, session.sortedEvents.length - 1))
          event.accepted = true
        } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
          eventsPage.selected = Math.max(0, eventsPage.selected - 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (session.page === "events") eventsPage.openEdit()
          event.accepted = true
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Color.background
        border.width: 1
        border.color: Qt.alpha(Color.accent, 0.45)

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.space(14)
          spacing: Style.space(10)

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)
            Text {
              text: "▣"
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.title
            }
            Text {
              text: "OMACASH"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.letterSpacing: 2
              font.bold: true
            }
            Text {
              text: "v" + session.version
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
            Item { Layout.fillWidth: true }
            Text {
              text: "Local-first personal finance  //  Yours. On your device."
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              text: root.clockText
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignRight
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.space(12)

            Sidebar {
              Layout.fillHeight: true
              current: session.page
              session: session
              onPageChosen: function (id) { session.setPage(id) }
            }

            Rectangle {
              width: 1
              Layout.fillHeight: true
              color: Qt.alpha(Color.accent, 0.25)
            }

            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true

              Dashboard {
                anchors.fill: parent
                visible: session.page === "dashboard"
                session: session
              }
              EventsPage {
                id: eventsPage
                anchors.fill: parent
                visible: session.page === "events"
                session: session
              }
              SettingsPage {
                anchors.fill: parent
                visible: session.page === "settings"
                session: session
              }
              PrivacyPage {
                anchors.fill: parent
                visible: session.page === "privacy"
                session: session
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: session.status || session.persistError || "Balance today. A brighter tomorrow."
              color: session.status || session.persistError ? Color.urgent : Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
            }
            Text {
              text: "OMACASH  v" + session.version
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        KeysSheet {
          id: sheet
          anchors.centerIn: parent
          width: Math.min(parent.width - 80, 420)
          height: Math.min(parent.height - 80, 480)
          bindings: session.bindings
        }
      }
    }
  }
}
