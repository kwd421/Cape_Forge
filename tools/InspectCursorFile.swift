import Foundation

@main
struct InspectCursorFile {
    static func main() throws {
        guard CommandLine.arguments.count >= 2 else {
            fputs("usage: InspectCursorFile <ani-or-cur-path>\n", stderr)
            exit(1)
        }

        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let parser = AniParser()
        let animation = try parser.parseCursorFile(at: url)
        let first = animation.frames.first!
        let rep = first.image.representations.compactMap { $0 as? NSBitmapImageRep }.max {
            ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
        }

        print("File: \(url.lastPathComponent)")
        print("Frames: \(animation.frames.count)")
        print("Canvas: \(Int(animation.canvasSize.width))x\(Int(animation.canvasSize.height))")
        print("Hotspot: \(Int(animation.hotspot.x)),\(Int(animation.hotspot.y))")
        if let rep {
            print("FirstFramePixels: \(rep.pixelsWide)x\(rep.pixelsHigh)")
        }
    }
}
