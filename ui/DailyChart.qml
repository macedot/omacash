import QtQuick
import qs.Commons

Canvas {
  id: root
  property var days: []
  property color incomeColor: Color.accent
  property color expenseColor: Color.urgent
  property color balanceColor: Color.foreground

  onDaysChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var rows = days || []
    if (rows.length < 2 || width < 8 || height < 8) return
    var maxAbs = 1
    var minBal = rows[0].balance
    var maxBal = rows[0].balance
    for (var i = 0; i < rows.length; i++) {
      maxAbs = Math.max(maxAbs, Math.abs(rows[i].cashflow))
      if (rows[i].balance < minBal) minBal = rows[i].balance
      if (rows[i].balance > maxBal) maxBal = rows[i].balance
    }
    if (minBal === maxBal) { minBal -= 1; maxBal += 1 }
    var pad = 4
    var plotH = height - pad * 2
    var n = rows.length
    var barW = Math.max(1, (width - pad * 2) / n * 0.6)
    for (var d = 0; d < n; d++) {
      var x = pad + d * (width - pad * 2) / n
      var cf = rows[d].cashflow
      var h = (Math.abs(cf) / maxAbs) * (plotH * 0.45)
      ctx.fillStyle = cf >= 0 ? incomeColor : expenseColor
      if (cf >= 0) ctx.fillRect(x, height / 2 - h, barW, h)
      else ctx.fillRect(x, height / 2, barW, h)
    }
    ctx.beginPath()
    ctx.strokeStyle = balanceColor
    ctx.lineWidth = 1.5
    for (var b = 0; b < n; b++) {
      var bx = pad + b * (width - pad * 2) / Math.max(1, n - 1)
      var by = pad + plotH - ((rows[b].balance - minBal) / (maxBal - minBal)) * plotH
      if (b === 0) ctx.moveTo(bx, by)
      else ctx.lineTo(bx, by)
    }
    ctx.stroke()
  }
}
