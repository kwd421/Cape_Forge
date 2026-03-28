import AppKit
import Foundation

let exportedURL = URL(fileURLWithPath: "/tmp/codex_saber_export_verify.cape")
let dumpedURL = URL(fileURLWithPath: "/tmp/codex_saber_dump_verify.cape")

func loadCursors(_ url: URL) throws -> [String: [String: Any]] {
    let data = try Data(contentsOf: url)
    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
    return plist["Cursors"] as! [String: [String: Any]]
}

func pngHash(from cursor: [String: Any]) -> String? {
    guard let reps = cursor["Representations"] as? [Data], let first = reps.first, let image = NSImage(data: first) else {
        return nil
    }
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        return nil
    }
    return png.base64EncodedString()
}

let ids = [
    "com.apple.coregraphics.Arrow",
    "com.apple.cursor.0",
    "com.apple.coregraphics.IBeam",
    "com.apple.coregraphics.IBeamXOR",
    "com.apple.cursor.2",
    "com.apple.cursor.13",
    "com.apple.coregraphics.Copy",
    "com.apple.cursor.5",
    "com.apple.cursor.7",
    "com.apple.cursor.8",
    "com.apple.coregraphics.Move",
    "com.apple.cursor.11",
    "com.apple.cursor.12",
    "com.apple.cursor.3",
    "com.apple.cursor.4",
    "com.apple.coregraphics.Wait",
    "com.apple.cursor.40",
    "com.apple.cursor.20",
    "com.apple.cursor.41",
    "com.apple.coregraphics.Alias",
    "com.apple.cursor.23",
    "com.apple.cursor.32",
    "com.apple.cursor.19",
    "com.apple.cursor.28",
    "com.apple.cursor.34",
    "com.apple.cursor.30"
]

let exported = try loadCursors(exportedURL)
let dumped = try loadCursors(dumpedURL)

var missing: [String] = []
var frameMismatches: [String] = []
var pixelMismatches: [String] = []

for id in ids {
    guard let exp = exported[id], let dump = dumped[id] else {
        missing.append(id)
        continue
    }

    let expFrames = exp["FrameCount"] as? Int
    let dumpFrames = dump["FrameCount"] as? Int
    if expFrames != dumpFrames {
        frameMismatches.append("\(id): \(String(describing: expFrames)) != \(String(describing: dumpFrames))")
    }

    if pngHash(from: exp) != pngHash(from: dump) {
        pixelMismatches.append(id)
    }
}

print("CHECKED \(ids.count)")
print("MISSING \(missing.count)")
if !missing.isEmpty {
    print(missing.joined(separator: "\n"))
}
print("FRAME_MISMATCHES \(frameMismatches.count)")
if !frameMismatches.isEmpty {
    print(frameMismatches.joined(separator: "\n"))
}
print("PIXEL_MISMATCHES \(pixelMismatches.count)")
if !pixelMismatches.isEmpty {
    print(pixelMismatches.joined(separator: "\n"))
}
