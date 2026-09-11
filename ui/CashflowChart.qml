import QtQuick
import qs.Commons

Canvas {
  id: root
  property var series: []
  property color incomeColor: Color.accent
  property color expenseColor: Color.urgent
  property color netColor: Color.muted
  property string fontFamily: Style.font.family
  property int fontSize: Style.font.caption
  implicitHeight: 160

  onSeriesChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onIncomeColorChanged: requestPaint()
  onExpenseColorChanged: requestPaint()
  onNetColorChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var rows = series || []
    if (!rows.length || width < 8 || height < 8) return

    var max = 1
    for (var i = 0; i < rows.length; i++) {
      max = Math.max(max, Math.abs(rows[i].income), Math.abs(rows[i].expense), Math.abs(rows[i].net))
    }
    var padL = 36
    var padB = 22
    var padT = 8
    var plotW = width - padL - 8
    var plotH = height - padB - padT
    var zeroY = padT + plotH / 2
    var groupW = plotW / rows.length
    var barW = Math.max(2, Math.min(10, groupW / 5))

    ctx.strokeStyle = Qt.alpha(Color.foreground, 0.12)
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(padL, zeroY)
    ctx.lineTo(width - 8, zeroY)
    ctx.stroke()

    ctx.fillStyle = Color.muted
    ctx.font = fontSize + "px " + fontFamily
    ctx.fillText(formatAxis(max), 2, padT + 10)
    ctx.fillText("0", 2, zeroY + 4)
    ctx.fillText("-" + formatAxis(max), 2, padT + plotH)

    for (var g = 0; g < rows.length; g++) {
      var cx = padL + g * groupW + groupW / 2
      var inc = rows[g].income || 0
      var exp = rows[g].expense || 0
      var net = rows[g].net || 0
      drawBar(ctx, cx - barW * 1.4, zeroY, barW, inc, max, plotH / 2, incomeColor, true)
      drawBar(ctx, cx, zeroY, barW, exp, max, plotH / 2, expenseColor, false)
      drawBar(ctx, cx + barW * 1.4, zeroY, barW, net, max, plotH / 2, netColor, net >= 0)
      ctx.fillStyle = Color.muted
      ctx.font = fontSize + "px " + fontFamily
      var label = rows[g].label || ""
      ctx.fillText(label, cx - ctx.measureText(label).width / 2, height - 6)
    }
  }

  function formatAxis(n) {
    if (Math.abs(n) >= 1000) return (n / 1000).toFixed(0) + "k"
    return String(Math.round(n))
  }

  function drawBar(ctx, x, zeroY, w, value, max, half, color, up) {
    var h = (Math.abs(value) / max) * half
    ctx.fillStyle = color
    if (up) ctx.fillRect(x - w / 2, zeroY - h, w, h)
    else ctx.fillRect(x - w / 2, zeroY, w, h)
  }
}
