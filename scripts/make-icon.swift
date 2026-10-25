import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let tile = NSBezierPath(roundedRect: NSRect(x: 40, y: 40, width: 944, height: 944), xRadius: 216, yRadius: 216)
NSGradient(starting: NSColor(srgbRed: 0.22, green: 0.14, blue: 0.54, alpha: 1),
           ending: NSColor(srgbRed: 0.55, green: 0.40, blue: 0.98, alpha: 1))!.draw(in: tile, angle: 55)
let eye = NSBezierPath()
eye.move(to: NSPoint(x: 206, y: 512))
eye.curve(to: NSPoint(x: 818, y: 512), controlPoint1: NSPoint(x: 392, y: 772), controlPoint2: NSPoint(x: 632, y: 772))
eye.curve(to: NSPoint(x: 206, y: 512), controlPoint1: NSPoint(x: 632, y: 252), controlPoint2: NSPoint(x: 392, y: 252))
eye.close()
NSColor.white.withAlphaComponent(0.94).setStroke()
eye.lineWidth = 40
eye.lineJoinStyle = .round
eye.stroke()
let iris = NSBezierPath(ovalIn: NSRect(x: 420, y: 420, width: 184, height: 184))
iris.lineWidth = 36
iris.stroke()
let slash = NSBezierPath()
slash.move(to: NSPoint(x: 282, y: 758))
slash.line(to: NSPoint(x: 742, y: 266))
slash.lineCapStyle = .round
NSColor(srgbRed: 0.37, green: 0.25, blue: 0.76, alpha: 1).setStroke()
slash.lineWidth = 94
slash.stroke()
NSColor.white.setStroke()
slash.lineWidth = 40
slash.stroke()
NSColor(srgbRed: 0.67, green: 0.98, blue: 0.81, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 772, y: 762, width: 60, height: 60)).fill()
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("docs/icon.png"))
