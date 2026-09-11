import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Format.js" as Format

Item {
  id: root
  property var session
  property int selected: 0
  property bool formOpen: false
  property bool editing: false

  function selectedEvent() {
    var list = session.sortedEvents
    if (!list.length) return null
    var i = Math.max(0, Math.min(selected, list.length - 1))
    return list[i]
  }

  function openNew() {
    form.setDraft({ currency: session.currency, frequency: "monthly", value: 0 })
    editing = false
    formOpen = true
  }

  function openEdit() {
    var ev = selectedEvent()
    if (!ev) return
    form.setDraft(ev)
    editing = true
    formOpen = true
  }

  function removeSelected() {
    var ev = selectedEvent()
    if (!ev) return
    session.removeEvent(ev.id)
    if (selected >= session.sortedEvents.length) selected = Math.max(0, session.sortedEvents.length - 1)
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(10)

    RowLayout {
      Layout.fillWidth: true
      Text {
        text: "EVENTS"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.subtitle
        font.letterSpacing: 1.5
        font.bold: true
      }
      Text {
        text: "Recurring income and expenses. Forecast hits, not a bank feed."
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        Layout.fillWidth: true
      }
      Button { text: "Import"; bordered: true; onClicked: session.importFromDownloads() }
      Button { text: "Export events"; bordered: true; onClicked: session.exportEventsToDownloads() }
      Button { text: "Export results"; bordered: true; onClicked: session.exportResultsToDownloads() }
      Button { text: "New"; bordered: true; onClicked: root.openNew() }
    }

    DailyChart {
      Layout.fillWidth: true
      Layout.preferredHeight: Style.space(90)
      days: session.detailResults
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "transparent"
      border.width: 1
      border.color: Qt.alpha(Color.accent, 0.28)
      clip: true

      ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 1
        model: session.sortedEvents
        clip: true
        header: RowLayout {
          width: list.width
          height: Style.space(24)
          spacing: 0
          Repeater {
            model: [
              { key: "", label: "Name", w: 3 },
              { key: "startDate", label: "Period", w: 3 },
              { key: "frequency", label: "Freq", w: 2 },
              { key: "value", label: "Value", w: 2 }
            ]
            delegate: Text {
              required property var modelData
              text: modelData.label
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              Layout.fillWidth: true
              Layout.preferredWidth: modelData.w
              leftPadding: Style.space(8)
              MouseArea {
                anchors.fill: parent
                enabled: modelData.key !== ""
                onClicked: session.cycleSort(modelData.key)
              }
            }
          }
        }
        delegate: Rectangle {
          required property var modelData
          required property int index
          width: list.width
          height: Style.space(28)
          color: index === root.selected ? Qt.alpha(Color.accent, 0.16) : "transparent"
          RowLayout {
            anchors.fill: parent
            Text {
              text: modelData.name + (modelData.category ? "  ·  " + modelData.category : "")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              Layout.fillWidth: true
              Layout.preferredWidth: 3
              leftPadding: Style.space(8)
            }
            Text {
              text: modelData.startDate + (modelData.endDate ? " → " + modelData.endDate : "")
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
              Layout.preferredWidth: 3
            }
            Text {
              text: modelData.frequency
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
              Layout.preferredWidth: 2
            }
            Text {
              text: Format.signedMoney(modelData.value, modelData.currency || session.currency)
              color: modelData.value < 0 ? Color.urgent : Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              Layout.fillWidth: true
              Layout.preferredWidth: 2
              horizontalAlignment: Text.AlignRight
              rightPadding: Style.space(8)
            }
          }
          MouseArea {
            anchors.fill: parent
            onClicked: root.selected = index
            onDoubleClicked: root.openEdit()
          }
        }

        Text {
          visible: session.sortedEvents.length === 0
          anchors.centerIn: parent
          text: "No events. Press n to add income or an expense."
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
      }
    }

    Text {
      visible: session.csvNotice !== ""
      text: session.csvNotice
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  EventForm {
    id: form
    visible: root.formOpen
    editing: root.editing
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    onCanceled: root.formOpen = false
    onSaved: {
      if (session.upsertEvent(form.draft, root.editing ? form.draft.id : ""))
        root.formOpen = false
    }
  }
}
