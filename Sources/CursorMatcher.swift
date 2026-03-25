import AppKit
import CryptoKit
import Foundation

struct CursorObservation: Identifiable {
    let id = UUID()
    let role: CursorRole
    let hotspot: CGPoint
    let fingerprintPrefix: String
    let timestamp: Date
}

struct CursorMatcherSelfTestResult: Identifiable {
    let id = UUID()
    let name: String
    let expectedRole: CursorRole
    let observedRole: CursorRole

    var passed: Bool {
        expectedRole == observedRole
    }
}

@MainActor
final class CursorMatcher {
    private let standardCursors: [(cursor: NSCursor, role: CursorRole)]
    private let roleByFingerprint: [Data: CursorRole]
    private let defaultAnimations: [CursorRole: CursorAnimation]

    init() {
        _ = NSApplication.shared

        var mapping: [Data: CursorRole] = [:]
        var ambiguousFingerprints = Set<Data>()
        var previews: [CursorRole: CursorAnimation] = [:]
        var cursors: [(NSCursor, CursorRole)] = []

        func register(_ cursor: NSCursor, as role: CursorRole) {
            let fingerprint = Self.fingerprint(for: cursor)
            if let existing = mapping[fingerprint], existing != role {
                mapping.removeValue(forKey: fingerprint)
                ambiguousFingerprints.insert(fingerprint)
            } else if !ambiguousFingerprints.contains(fingerprint) {
                mapping[fingerprint] = role
            }
            previews[role] = Self.animation(for: cursor)
            cursors.append((cursor, role))
        }

        register(.arrow, as: .arrow)
        register(.iBeam, as: .text)
        register(.pointingHand, as: .link)
        register(.crosshair, as: .precision)
        register(.openHand, as: .move)
        register(.closedHand, as: .move)
        register(.operationNotAllowed, as: .unavailable)
        register(.resizeLeftRight, as: .horizontalResize)
        register(.resizeUpDown, as: .verticalResize)

        standardCursors = cursors
        roleByFingerprint = mapping
        defaultAnimations = previews
    }

    func currentObservation() -> CursorObservation {
        observation(for: NSCursor.current)
    }

    func currentRole() -> CursorRole {
        currentObservation().role
    }

    func defaultPreview(for role: CursorRole) -> CursorAnimation {
        defaultAnimations[role] ?? defaultAnimations[.arrow]!
    }

    func runSelfTest() -> [CursorMatcherSelfTestResult] {
        let testCases: [(String, NSCursor, CursorRole)] = [
            ("Arrow", .arrow, .arrow),
            ("IBeam", .iBeam, .text),
            ("Pointing Hand", .pointingHand, .link),
            ("Crosshair", .crosshair, .precision),
            ("Open Hand", .openHand, .move),
            ("Closed Hand", .closedHand, .move),
            ("Not Allowed", .operationNotAllowed, .unavailable),
            ("Resize Left Right", .resizeLeftRight, .horizontalResize),
            ("Resize Up Down", .resizeUpDown, .verticalResize)
        ]

        return testCases.map { name, cursor, expectedRole in
            let observation = observation(for: cursor)
            return CursorMatcherSelfTestResult(
                name: name,
                expectedRole: expectedRole,
                observedRole: observation.role
            )
        }
    }

    private func observation(for cursor: NSCursor) -> CursorObservation {
        let fingerprint = Self.fingerprint(for: cursor)
        let role = standardCursors.first(where: { registered, _ in
            cursor === registered || cursor.isEqual(registered)
        })?.role ?? roleByFingerprint[fingerprint] ?? .arrow
        let fingerprintPrefix = fingerprint.prefix(4).map { String(format: "%02x", $0) }.joined()
        return CursorObservation(
            role: role,
            hotspot: cursor.hotSpot,
            fingerprintPrefix: fingerprintPrefix,
            timestamp: Date()
        )
    }

    private static func fingerprint(for cursor: NSCursor) -> Data {
        let imageData = canonicalImageData(for: cursor.image)
        var payload = Data()
        payload.append(imageData)

        var width = Float(cursor.image.size.width)
        var height = Float(cursor.image.size.height)
        var hotX = Float(cursor.hotSpot.x)
        var hotY = Float(cursor.hotSpot.y)
        withUnsafeBytes(of: &width) { payload.append(contentsOf: $0) }
        withUnsafeBytes(of: &height) { payload.append(contentsOf: $0) }
        withUnsafeBytes(of: &hotX) { payload.append(contentsOf: $0) }
        withUnsafeBytes(of: &hotY) { payload.append(contentsOf: $0) }

        return Data(SHA256.hash(data: payload))
    }

    private static func canonicalImageData(for image: NSImage) -> Data {
        let proposedSize = image.size == .zero ? NSSize(width: 32, height: 32) : image.size
        let proposedRect = NSRect(origin: .zero, size: proposedSize)

        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            if let png = rep.representation(using: .png, properties: [:]) {
                return png
            }
        }

        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: max(Int(proposedRect.width.rounded(.up)), 1),
                pixelsHigh: max(Int(proposedRect.height.rounded(.up)), 1),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            return image.tiffRepresentation ?? Data()
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: proposedRect)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:]) ?? image.tiffRepresentation ?? Data()
    }

    private static func animation(for cursor: NSCursor) -> CursorAnimation {
        let size = cursor.image.size
        return CursorAnimation(
            frames: [CursorFrame(image: cursor.image, delay: 1.0)],
            hotspot: cursor.hotSpot,
            canvasSize: size == .zero ? CGSize(width: 32, height: 32) : size
        )
    }
}
