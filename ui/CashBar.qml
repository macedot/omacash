import QtQuick
import Quickshell
import qs.Ui
import qs.Commons
import "Format.js" as Format

BarWidget {
  id: root
  moduleName: "com.omacash.cashflow"

  property bool opened: false
  property bool popoutSwitchClosing: false

  readonly property real balance: session.todayBalance
  readonly property string currency: session.currency
  readonly property string label: Format.compact(balance, currency)
  readonly property bool negative: balance < 0
  readonly property bool empty: !session.events || session.events.length === 0

  function open() {
    popoutSwitchClosing = false
    opened = true
  }
  function close() { opened = false }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
  }
  function expand() {
    Quickshell.execDetached(["omarchy", "shell", "shell", "toggle", "com.omacash.cashflow", "{}"])
    close()
  }

  Session { id: session }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    tooltipText: root.empty ? "Omacash — add an event" : ("Cash on hand " + Format.money(root.balance, root.currency))
    active: root.opened
    useActiveColor: root.negative
    dimmed: root.empty
    onPressed: function (b) {
      if (b === Qt.RightButton) root.expand()
      else if (b === Qt.LeftButton) {
        if (root.opened) root.close()
        else root.open()
      }
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.opened
    padding: 12
    borderSpec: Border.flat(Color.accent, 2)
    contentWidth: 320
    contentHeight: 280
    focusTarget: content.item
    Loader {
      id: content
      anchors.fill: parent
      active: root.opened
      sourceComponent: Popover {
        session: root.session
        onCloseRequested: root.close()
        onExpandRequested: root.expand()
      }
    }
  }
}
