import QtQuick
import qs.Commons

Canvas {
  id: root
  property var points: []
  property color stroke: Color.accent
  onPointsChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onStrokeChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var pts = points || []
    if (pts.length < 2 || width < 2 || height < 2) return
    var min = pts[0]
    var max = pts[0]
    for (var i = 1; i < pts.length; i++) {
      if (pts[i] < min) min = pts[i]
      if (pts[i] > max) max = pts[i]
    }
    if (min === max) {
      min -= 1
      max += 1
    }
    ctx.beginPath()
    ctx.strokeStyle = stroke
    ctx.lineWidth = 1.5
    for (var p = 0; p < pts.length; p++) {
      var x = p * (width - 2) / (pts.length - 1)
      var y = height - 2 - ((pts[p] - min) / (max - min)) * (height - 4)
      if (p === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.stroke()
  }
}
