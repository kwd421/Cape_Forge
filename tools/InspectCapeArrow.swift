import AppKit
import Foundation

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: InspectCapeArrow <cape-path>\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try Data(contentsOf: url)
let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
let cursors = plist["Cursors"] as! [String: Any]
let arrow = cursors["com.apple.coregraphics.Arrow"] as! [String: Any]

let frameCount = arrow["FrameCount"] ?? "?"
let pointsWide = arrow["PointsWide"] ?? "?"
let pointsHigh = arrow["PointsHigh"] ?? "?"
print("FrameCount: \(frameCount)")
print("PointsWide: \(pointsWide)")
print("PointsHigh: \(pointsHigh)")

if let reps = arrow["Representations"] as? [Data], let first = reps.first, let image = NSImage(data: first) {
    let rep = image.representations.compactMap { $0 as? NSBitmapImageRep }.max {
        ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
    }
    if let rep {
        print("RepresentationPixels: \(rep.pixelsWide)x\(rep.pixelsHigh)")
    } else {
        print("RepresentationPixels: unknown")
    }
} else {
    print("RepresentationPixels: missing")
}
