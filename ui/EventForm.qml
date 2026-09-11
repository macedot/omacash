import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Rectangle {
  id: root
  property var draft: ({
    name: "",
    startDate: "",
    endDate: "",
    frequency: "monthly",
    value: 0,
    currency: "USD",
    category: ""
  })
  property bool editing: false
  signal saved()
  signal canceled()

  color: Qt.alpha(Color.background, 0.97)
  border.width: 1
  border.color: Color.accent
  implicitHeight: col.implicitHeight + Style.space(24)

  function setDraft(next) {
    draft = {
      name: next.name || "",
      startDate: next.startDate || "",
      endDate: next.endDate || "",
      frequency: next.frequency || "monthly",
      value: next.value || 0,
      currency: next.currency || "USD",
      category: next.category || "",
      id: next.id || ""
    }
  }

  ColumnLayout {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(14)
    spacing: Style.space(8)

    Text {
      text: root.editing ? "Edit event" : "New event"
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
      font.bold: true
    }

    GridLayout {
      columns: 2
      columnSpacing: Style.space(10)
      rowSpacing: Style.space(8)
      Layout.fillWidth: true

      TextField { id: nameField; placeholderText: "Name"; text: root.draft.name; Layout.fillWidth: true; onEditingFinished: root.draft.name = text }
      TextField { id: catField; placeholderText: "Category"; text: root.draft.category; Layout.fillWidth: true; onEditingFinished: root.draft.category = text }
      TextField { id: startField; placeholderText: "Start YYYY-MM-DD"; text: root.draft.startDate; Layout.fillWidth: true; onEditingFinished: root.draft.startDate = text }
      TextField { id: endField; placeholderText: "End (optional)"; text: root.draft.endDate; Layout.fillWidth: true; onEditingFinished: root.draft.endDate = text }
      Dropdown {
        Layout.fillWidth: true
        label: "Frequency"
        value: root.draft.frequency
        options: ["daily", "weekly", "monthly", "quarterly", "semi-annual", "annual"]
        onChanged: function (v) { root.draft.frequency = v }
      }
      Dropdown {
        Layout.fillWidth: true
        label: "Currency"
        value: root.draft.currency
        options: ["USD", "EUR", "GBP", "BRL"]
        onChanged: function (v) { root.draft.currency = v }
      }
      TextField {
        id: valueField
        placeholderText: "Value (negative = expense)"
        text: String(root.draft.value)
        Layout.fillWidth: true
        Layout.columnSpan: 2
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      Item { Layout.fillWidth: true }
      Button { text: "Cancel"; bordered: true; onClicked: root.canceled() }
      Button { text: "Save"; bordered: true; onClicked: {
        root.draft.name = nameField.text
        root.draft.category = catField.text
        root.draft.startDate = startField.text
        root.draft.endDate = endField.text
        root.draft.value = Number(valueField.text)
        root.saved()
      } }
    }
  }
}
