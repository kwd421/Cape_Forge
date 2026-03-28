import AppKit
import Foundation

struct Palette {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let accent: NSColor
    let accentSoft: NSColor
    let stroke: NSColor
}

enum Concept: String, CaseIterable {
    case refined = "capeforge-icon-refined"
    case forge = "capeforge-icon-forge"
    case hammer = "capeforge-icon-hammer"

    var title: String {
        switch self {
        case .refined: return "Refined"
        case .forge: return "Forge"
        case .hammer: return "Hammer"
        }
    }

    var palette: Palette {
        switch self {
        case .refined:
            return Palette(
                backgroundTop: NSColor(calibratedRed: 0.18, green: 0.56, blue: 0.98, alpha: 1),
                backgroundBottom: NSColor(calibratedRed: 0.05, green: 0.15, blue: 0.42, alpha: 1),
                accent: NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.28, alpha: 1),
                accentSoft: NSColor(calibratedRed: 0.81, green: 0.90, blue: 1.00, alpha: 1),
                stroke: NSColor(calibratedRed: 0.03, green: 0.09, blue: 0.24, alpha: 0.92)
            )
        case .forge:
            return Palette(
                backgroundTop: NSColor(calibratedRed: 0.13, green: 0.17, blue: 0.28, alpha: 1),
                backgroundBottom: NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.13, alpha: 1),
                accent: NSColor(calibratedRed: 1.00, green: 0.49, blue: 0.18, alpha: 1),
                accentSoft: NSColor(calibratedRed: 1.00, green: 0.83, blue: 0.53, alpha: 1),
                stroke: NSColor(calibratedRed: 0.95, green: 0.96, blue: 1.00, alpha: 0.92)
            )
        case .hammer:
            return Palette(
                backgroundTop: NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.96, alpha: 1),
                backgroundBottom: NSColor(calibratedRed: 0.06, green: 0.12, blue: 0.30, alpha: 1),
                accent: NSColor(calibratedRed: 1.00, green: 0.70, blue: 0.16, alpha: 1),
                accentSoft: NSColor(calibratedRed: 0.86, green: 0.93, blue: 1.00, alpha: 1),
                stroke: NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.14, alpha: 0.95)
            )
        }
    }
}

let fileManager = FileManager.default
let outputDirectory = URL(fileURLWithPath: "/Users/seinel/Projects/mac_mouse_cursor/icon-concepts", isDirectory: true)
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func makeBitmap(size: Int) -> NSBitmapImageRep {
    NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
}

func drawShadow(_ color: NSColor, blur: CGFloat, offset: CGSize) {
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = offset
    shadow.set()
}

func drawBase(size: CGFloat, palette: Palette) {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let outerInset = size * 0.035
    let shellRect = rect.insetBy(dx: outerInset, dy: outerInset)
    let shellPath = NSBezierPath(roundedRect: shellRect, xRadius: size * 0.23, yRadius: size * 0.23)

    drawShadow(NSColor(calibratedWhite: 0, alpha: 0.18), blur: size * 0.05, offset: CGSize(width: 0, height: -size * 0.015))
    let baseGradient = NSGradient(colors: [palette.backgroundTop, palette.backgroundBottom])!
    baseGradient.draw(in: shellPath, angle: 270)

    NSGraphicsContext.current?.cgContext.saveGState()
    shellPath.addClip()
    let glowGradient = NSGradient(colors: [
        palette.accent.withAlphaComponent(0.28),
        palette.accent.withAlphaComponent(0.0)
    ])!
    glowGradient.draw(fromCenter: NSPoint(x: size * 0.25, y: size * 0.78), radius: 0, toCenter: NSPoint(x: size * 0.25, y: size * 0.78), radius: size * 0.48, options: [])
    NSGraphicsContext.current?.cgContext.restoreGState()

    palette.stroke.withAlphaComponent(0.16).setStroke()
    shellPath.lineWidth = size * 0.014
    shellPath.stroke()

    let innerRect = shellRect.insetBy(dx: size * 0.03, dy: size * 0.03)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: size * 0.19, yRadius: size * 0.19)
    NSColor.white.withAlphaComponent(0.06).setStroke()
    innerPath.lineWidth = size * 0.008
    innerPath.stroke()
}

func drawRefinedConcept(size: CGFloat, palette: Palette) {
    let capeRect = NSRect(x: size * 0.56, y: size * 0.20, width: size * 0.20, height: size * 0.22)
    let cape = NSBezierPath()
    cape.move(to: NSPoint(x: capeRect.minX, y: capeRect.maxY))
    cape.line(to: NSPoint(x: capeRect.maxX, y: capeRect.maxY))
    cape.line(to: NSPoint(x: capeRect.maxX - size * 0.015, y: capeRect.minY + size * 0.02))
    cape.line(to: NSPoint(x: capeRect.midX, y: capeRect.minY))
    cape.line(to: NSPoint(x: capeRect.minX + size * 0.015, y: capeRect.minY + size * 0.02))
    cape.close()
    palette.accentSoft.withAlphaComponent(0.95).setFill()
    cape.fill()
    palette.stroke.withAlphaComponent(0.35).setStroke()
    cape.lineWidth = size * 0.008
    cape.stroke()

    let pointer = NSBezierPath()
    pointer.move(to: NSPoint(x: size * 0.30, y: size * 0.77))
    pointer.line(to: NSPoint(x: size * 0.66, y: size * 0.42))
    pointer.line(to: NSPoint(x: size * 0.53, y: size * 0.42))
    pointer.line(to: NSPoint(x: size * 0.71, y: size * 0.16))
    pointer.line(to: NSPoint(x: size * 0.57, y: size * 0.11))
    pointer.line(to: NSPoint(x: size * 0.42, y: size * 0.38))
    pointer.line(to: NSPoint(x: size * 0.42, y: size * 0.26))
    pointer.close()

    drawShadow(NSColor(calibratedWhite: 0, alpha: 0.26), blur: size * 0.04, offset: CGSize(width: 0, height: -size * 0.015))
    NSColor.white.setFill()
    pointer.fill()
    palette.stroke.setStroke()
    pointer.lineWidth = size * 0.022
    pointer.lineJoinStyle = .round
    pointer.stroke()

    let spark = NSBezierPath()
    spark.move(to: NSPoint(x: size * 0.72, y: size * 0.62))
    spark.line(to: NSPoint(x: size * 0.76, y: size * 0.72))
    spark.line(to: NSPoint(x: size * 0.86, y: size * 0.76))
    spark.line(to: NSPoint(x: size * 0.76, y: size * 0.80))
    spark.line(to: NSPoint(x: size * 0.72, y: size * 0.90))
    spark.line(to: NSPoint(x: size * 0.68, y: size * 0.80))
    spark.line(to: NSPoint(x: size * 0.58, y: size * 0.76))
    spark.line(to: NSPoint(x: size * 0.68, y: size * 0.72))
    spark.close()
    palette.accent.setFill()
    spark.fill()
}

func drawForgeConcept(size: CGFloat, palette: Palette) {
    let anvil = NSBezierPath()
    anvil.move(to: NSPoint(x: size * 0.22, y: size * 0.56))
    anvil.line(to: NSPoint(x: size * 0.58, y: size * 0.56))
    anvil.line(to: NSPoint(x: size * 0.72, y: size * 0.64))
    anvil.line(to: NSPoint(x: size * 0.84, y: size * 0.64))
    anvil.line(to: NSPoint(x: size * 0.72, y: size * 0.52))
    anvil.line(to: NSPoint(x: size * 0.54, y: size * 0.50))
    anvil.line(to: NSPoint(x: size * 0.50, y: size * 0.34))
    anvil.line(to: NSPoint(x: size * 0.62, y: size * 0.22))
    anvil.line(to: NSPoint(x: size * 0.42, y: size * 0.22))
    anvil.line(to: NSPoint(x: size * 0.34, y: size * 0.34))
    anvil.line(to: NSPoint(x: size * 0.30, y: size * 0.50))
    anvil.line(to: NSPoint(x: size * 0.18, y: size * 0.52))
    anvil.close()

    let metalGradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.95, alpha: 1),
        NSColor(calibratedWhite: 0.72, alpha: 1),
        NSColor(calibratedWhite: 0.58, alpha: 1)
    ])!
    drawShadow(NSColor(calibratedWhite: 0, alpha: 0.28), blur: size * 0.04, offset: CGSize(width: 0, height: -size * 0.015))
    metalGradient.draw(in: anvil, angle: 270)
    NSColor.white.withAlphaComponent(0.30).setStroke()
    anvil.lineWidth = size * 0.01
    anvil.stroke()

    let cursor = NSBezierPath()
    cursor.move(to: NSPoint(x: size * 0.23, y: size * 0.79))
    cursor.line(to: NSPoint(x: size * 0.47, y: size * 0.55))
    cursor.line(to: NSPoint(x: size * 0.39, y: size * 0.55))
    cursor.line(to: NSPoint(x: size * 0.51, y: size * 0.36))
    cursor.line(to: NSPoint(x: size * 0.41, y: size * 0.32))
    cursor.line(to: NSPoint(x: size * 0.31, y: size * 0.51))
    cursor.line(to: NSPoint(x: size * 0.31, y: size * 0.42))
    cursor.close()
    NSColor.white.setFill()
    cursor.fill()
    palette.stroke.setStroke()
    cursor.lineWidth = size * 0.018
    cursor.lineJoinStyle = .round
    cursor.stroke()

    let ember = NSBezierPath(ovalIn: NSRect(x: size * 0.56, y: size * 0.69, width: size * 0.15, height: size * 0.15))
    let emberGradient = NSGradient(colors: [palette.accentSoft, palette.accent])!
    emberGradient.draw(in: ember, relativeCenterPosition: .zero)

    let flare = NSBezierPath()
    flare.move(to: NSPoint(x: size * 0.67, y: size * 0.88))
    flare.line(to: NSPoint(x: size * 0.70, y: size * 0.79))
    flare.line(to: NSPoint(x: size * 0.79, y: size * 0.76))
    flare.line(to: NSPoint(x: size * 0.70, y: size * 0.73))
    flare.line(to: NSPoint(x: size * 0.67, y: size * 0.64))
    flare.line(to: NSPoint(x: size * 0.64, y: size * 0.73))
    flare.line(to: NSPoint(x: size * 0.55, y: size * 0.76))
    flare.line(to: NSPoint(x: size * 0.64, y: size * 0.79))
    flare.close()
    palette.accent.setFill()
    flare.fill()
}

func drawHammerConcept(size: CGFloat, palette: Palette) {
    let cursor = NSBezierPath()
    cursor.move(to: NSPoint(x: size * 0.23, y: size * 0.79))
    cursor.line(to: NSPoint(x: size * 0.56, y: size * 0.46))
    cursor.line(to: NSPoint(x: size * 0.45, y: size * 0.46))
    cursor.line(to: NSPoint(x: size * 0.62, y: size * 0.17))
    cursor.line(to: NSPoint(x: size * 0.50, y: size * 0.12))
    cursor.line(to: NSPoint(x: size * 0.36, y: size * 0.40))
    cursor.line(to: NSPoint(x: size * 0.36, y: size * 0.28))
    cursor.close()

    drawShadow(NSColor(calibratedWhite: 0, alpha: 0.28), blur: size * 0.05, offset: CGSize(width: 0, height: -size * 0.016))
    NSColor.white.setFill()
    cursor.fill()
    palette.stroke.setStroke()
    cursor.lineWidth = size * 0.022
    cursor.lineJoinStyle = .round
    cursor.stroke()

    let bevel = NSBezierPath()
    bevel.move(to: NSPoint(x: size * 0.28, y: size * 0.73))
    bevel.line(to: NSPoint(x: size * 0.50, y: size * 0.51))
    bevel.line(to: NSPoint(x: size * 0.43, y: size * 0.51))
    bevel.line(to: NSPoint(x: size * 0.30, y: size * 0.64))
    bevel.close()
    palette.accentSoft.withAlphaComponent(0.45).setFill()
    bevel.fill()

    let hammerHandle = NSBezierPath(roundedRect: NSRect(x: size * 0.58, y: size * 0.48, width: size * 0.09, height: size * 0.30), xRadius: size * 0.03, yRadius: size * 0.03)
    let handleGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.53, green: 0.33, blue: 0.14, alpha: 1),
        NSColor(calibratedRed: 0.37, green: 0.22, blue: 0.09, alpha: 1)
    ])!
    handleGradient.draw(in: hammerHandle, angle: -90)

    let hammerHead = NSBezierPath(roundedRect: NSRect(x: size * 0.47, y: size * 0.66, width: size * 0.28, height: size * 0.12), xRadius: size * 0.04, yRadius: size * 0.04)
    let headGradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.97, alpha: 1),
        NSColor(calibratedWhite: 0.80, alpha: 1),
        NSColor(calibratedWhite: 0.67, alpha: 1)
    ])!
    drawShadow(NSColor(calibratedWhite: 0, alpha: 0.20), blur: size * 0.03, offset: CGSize(width: 0, height: -size * 0.012))
    headGradient.draw(in: hammerHead, angle: 270)
    NSColor.white.withAlphaComponent(0.28).setStroke()
    hammerHead.lineWidth = size * 0.008
    hammerHead.stroke()

    let impact = NSBezierPath()
    impact.move(to: NSPoint(x: size * 0.55, y: size * 0.48))
    impact.line(to: NSPoint(x: size * 0.60, y: size * 0.58))
    impact.line(to: NSPoint(x: size * 0.70, y: size * 0.62))
    impact.line(to: NSPoint(x: size * 0.60, y: size * 0.66))
    impact.line(to: NSPoint(x: size * 0.55, y: size * 0.76))
    impact.line(to: NSPoint(x: size * 0.50, y: size * 0.66))
    impact.line(to: NSPoint(x: size * 0.40, y: size * 0.62))
    impact.line(to: NSPoint(x: size * 0.50, y: size * 0.58))
    impact.close()
    palette.accent.withAlphaComponent(0.92).setFill()
    impact.fill()

    let sparkA = NSBezierPath(roundedRect: NSRect(x: size * 0.67, y: size * 0.46, width: size * 0.07, height: size * 0.018), xRadius: size * 0.008, yRadius: size * 0.008)
    sparkA.transform(using: AffineTransform(rotationByDegrees: 28))
    palette.accentSoft.setFill()
    sparkA.fill()

    let sparkB = NSBezierPath(roundedRect: NSRect(x: size * 0.41, y: size * 0.57, width: size * 0.08, height: size * 0.018), xRadius: size * 0.008, yRadius: size * 0.008)
    sparkB.transform(using: AffineTransform(rotationByDegrees: -28))
    palette.accentSoft.setFill()
    sparkB.fill()
}

func pngData(for concept: Concept, pixelSize: Int) -> Data {
    let rep = makeBitmap(size: pixelSize)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(pixelSize)
    drawBase(size: size, palette: concept.palette)
    switch concept {
    case .refined:
        drawRefinedConcept(size: size, palette: concept.palette)
    case .forge:
        drawForgeConcept(size: size, palette: concept.palette)
    case .hammer:
        drawHammerConcept(size: size, palette: concept.palette)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for concept in Concept.allCases {
    for size in [256, 512, 1024] {
        let data = pngData(for: concept, pixelSize: size)
        let fileURL = outputDirectory.appendingPathComponent("\(concept.rawValue)-\(size).png")
        try data.write(to: fileURL, options: .atomic)
    }
}

print("Generated icon concepts in \(outputDirectory.path)")
