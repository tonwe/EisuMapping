import AppKit

// A vector-drawn icon, rendered at each native .icns size without dependencies.
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func roundRect(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawWindow(_ rect: NSRect, fill: NSColor, stroke: NSColor) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.set()
    roundRect(rect, radius: 47, fill: fill)
    NSGraphicsContext.restoreGraphicsState()
    let outline = NSBezierPath(roundedRect: rect.insetBy(dx: 5, dy: 5), xRadius: 43, yRadius: 43)
    stroke.setStroke()
    outline.lineWidth = 10
    outline.stroke()
    let y = rect.maxY - 66
    for x in [rect.minX + 47, rect.minX + 78, rect.minX + 109] {
        stroke.withAlphaComponent(0.6).setFill()
        NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 15, height: 15)).fill()
    }
    let rule = NSBezierPath()
    rule.move(to: NSPoint(x: rect.minX + 7, y: rect.maxY - 96))
    rule.line(to: NSPoint(x: rect.maxX - 7, y: rect.maxY - 96))
    rule.lineWidth = 7
    stroke.withAlphaComponent(0.35).setStroke()
    rule.stroke()
}

func arrow(from: NSPoint, to: NSPoint, color: NSColor) {
    let line = NSBezierPath()
    line.move(to: from)
    line.line(to: to)
    let direction: CGFloat = to.x > from.x ? -1 : 1
    line.move(to: NSPoint(x: to.x + direction * 53, y: to.y + 53))
    line.line(to: to)
    line.line(to: NSPoint(x: to.x + direction * 53, y: to.y - 53))
    line.lineWidth = 34
    line.lineCapStyle = .round
    line.lineJoinStyle = .round
    color.setStroke()
    line.stroke()
}

func render(size: Int) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let tile = NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880), xRadius: 196, yRadius: 196)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 30
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor(calibratedRed: 0.18, green: 0.26, blue: 0.68, alpha: 1).setFill()
    tile.fill()
    NSShadow().set()
    NSGradient(
        starting: NSColor(calibratedRed: 0.26, green: 0.44, blue: 0.96, alpha: 1),
        ending: NSColor(calibratedRed: 0.13, green: 0.20, blue: 0.57, alpha: 1)
    )!.draw(in: tile, angle: -60)

    drawWindow(
        NSRect(x: 186, y: 450, width: 488, height: 342),
        fill: NSColor(calibratedRed: 0.48, green: 0.69, blue: 1, alpha: 1),
        stroke: NSColor.white.withAlphaComponent(0.82)
    )
    drawWindow(
        NSRect(x: 350, y: 258, width: 488, height: 342),
        fill: NSColor(calibratedWhite: 0.98, alpha: 1),
        stroke: NSColor(calibratedRed: 0.72, green: 0.79, blue: 0.95, alpha: 1)
    )
    arrow(
        from: NSPoint(x: 452, y: 410), to: NSPoint(x: 727, y: 410),
        color: NSColor(calibratedRed: 0.22, green: 0.38, blue: 0.86, alpha: 1))
    arrow(from: NSPoint(x: 557, y: 658), to: NSPoint(x: 282, y: 658), color: .white)
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try render(size: points).write(to: output.appendingPathComponent("icon_\(points)x\(points).png"))
    try render(size: points * 2).write(to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
