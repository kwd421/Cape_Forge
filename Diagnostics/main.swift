import AppKit
import Foundation

struct CursorFrame {
    let image: NSImage
    let delay: TimeInterval
}

struct CursorAnimation {
    let frames: [CursorFrame]
    let hotspot: CGPoint
    let canvasSize: CGSize
}

enum CursorRole: String, CaseIterable {
    case arrow
    case text
    case link
    case precision
    case move
    case unavailable
    case busy
    case verticalResize
    case horizontalResize
    case diagonalResizeNWSE
    case diagonalResizeNESW

    var themeFileName: String {
        switch self {
        case .arrow: return "독케익_일반선택.ani"
        case .text: return "독케익_텍스트 선택.ani"
        case .link: return "독케익_연결,위치,사용자 선택.ani"
        case .precision: return "독케익_정밀도 선택.ani"
        case .move: return "독케익_이동.ani"
        case .unavailable: return "독케익_사용할 수 없음.ani"
        case .busy: return "독케익_백그라운드 작업,사용중.ani"
        case .verticalResize: return "독케익_수직 크기 조절.ani"
        case .horizontalResize: return "독케익_수평 크기 조절.ani"
        case .diagonalResizeNWSE: return "독케익_대각선 방향 크기 조절 1.ani"
        case .diagonalResizeNESW: return "독케익_대각선 방향 크기 조절 2.ani"
        }
    }
}

enum CursorError: Error, LocalizedError {
    case missingTheme(String)
    case invalidANI(String)
    case invalidThemeSelection(String)
    case unsupportedCursorPayload

    var errorDescription: String? {
        switch self {
        case .missingTheme(let path): return "테마 파일이 없습니다: \(path)"
        case .invalidANI(let message): return "ANI 파싱 실패: \(message)"
        case .invalidThemeSelection(let message): return message
        case .unsupportedCursorPayload: return "커서 프레임을 이미지로 읽지 못했습니다."
        }
    }
}

struct AniParser {
    func parseCursorFile(at url: URL) throws -> CursorAnimation {
        switch url.pathExtension.lowercased() {
        case "ani":
            return try parseANI(at: url)
        case "cur":
            let data = try Data(contentsOf: url)
            return try parseCUR(data: data)
        default:
            throw CursorError.invalidANI("지원하지 않는 확장자입니다: \(url.pathExtension)")
        }
    }

    func parseANI(at url: URL) throws -> CursorAnimation {
        let data = try Data(contentsOf: url)
        return try parseANI(data: data)
    }

    func parseANI(data: Data) throws -> CursorAnimation {
        guard data.count >= 12, data[0..<4] == Data("RIFF".utf8), data[8..<12] == Data("ACON".utf8) else {
            throw CursorError.invalidANI("RIFF ACON 헤더가 아닙니다.")
        }

        var jiffies = 6
        var cursorChunks: [Data] = []
        var offset = 12

        while offset + 8 <= data.count {
            let chunkID = fourCC(data, offset)
            let chunkSize = Int(readUInt32LE(data, offset + 4))
            let chunkDataStart = offset + 8
            let chunkDataEnd = chunkDataStart + chunkSize
            guard chunkDataEnd <= data.count else {
                throw CursorError.invalidANI("청크 길이가 잘못되었습니다.")
            }

            if chunkID == "anih", chunkSize >= 36 {
                jiffies = Int(readUInt32LE(data, chunkDataStart + 28))
            } else if chunkID == "LIST", chunkSize >= 4 {
                let listType = fourCC(data, chunkDataStart)
                if listType == "fram" {
                    cursorChunks.append(contentsOf: try extractIconChunks(from: Data(data[chunkDataStart + 4..<chunkDataEnd])))
                }
            } else if chunkID == "rate", chunkSize >= 4 {
                jiffies = Int(readUInt32LE(data, chunkDataStart))
            }

            offset = chunkDataEnd + (chunkSize & 1)
        }

        let frames = try cursorChunks.map { chunk in
            try decodeFrame(from: chunk, defaultDelay: TimeInterval(max(jiffies, 1)) / 60.0)
        }
        guard let first = frames.first else {
            throw CursorError.invalidANI("프레임이 없습니다.")
        }

        return CursorAnimation(
            frames: frames.map { CursorFrame(image: $0.image, delay: $0.delay) },
            hotspot: first.hotspot,
            canvasSize: first.size
        )
    }

    func parseCUR(data: Data) throws -> CursorAnimation {
        let frame = try decodeFrame(from: data, defaultDelay: 1.0)
        return CursorAnimation(
            frames: [CursorFrame(image: frame.image, delay: 1.0)],
            hotspot: frame.hotspot,
            canvasSize: frame.size
        )
    }

    private func extractIconChunks(from data: Data) throws -> [Data] {
        var chunks: [Data] = []
        var offset = data.startIndex
        while offset + 8 <= data.endIndex {
            let chunkID = fourCC(data, offset)
            let chunkSize = Int(readUInt32LE(data, offset + 4))
            let start = offset + 8
            let end = start + chunkSize
            guard end <= data.endIndex else {
                throw CursorError.invalidANI("icon 청크 길이가 잘못되었습니다.")
            }
            if chunkID == "icon" {
                chunks.append(data[start..<end])
            }
            offset = end + (chunkSize & 1)
        }
        return chunks
    }

    private func decodeFrame(from data: Data, defaultDelay: TimeInterval) throws -> (image: NSImage, hotspot: CGPoint, size: CGSize, delay: TimeInterval) {
        let data = Data(data)
        guard data.count >= 22 else {
            throw CursorError.invalidANI("CUR 데이터가 너무 짧습니다.")
        }
        let type = readUInt16LE(data, 2)
        let count = readUInt16LE(data, 4)
        guard type == 2, count >= 1 else {
            throw CursorError.invalidANI("CUR 헤더가 아닙니다.")
        }

        let widthByte = Int(data[6])
        let heightByte = Int(data[7])
        let hotspotX = Int(readUInt16LE(data, 10))
        let hotspotY = Int(readUInt16LE(data, 12))
        let imageBytes = Int(readUInt32LE(data, 14))
        let imageOffset = Int(readUInt32LE(data, 18))
        guard imageOffset + imageBytes <= data.count else {
            throw CursorError.invalidANI("CUR 내부 이미지 범위가 잘못되었습니다.")
        }

        let imagePayload = Data(data[imageOffset..<(imageOffset + imageBytes)])
        guard let image = NSImage(data: imagePayload) else {
            throw CursorError.unsupportedCursorPayload
        }

        let rep = image.representations.compactMap { $0 as? NSBitmapImageRep }.max {
            ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
        }
        let width = rep?.pixelsWide ?? max(widthByte, 32)
        let height = rep?.pixelsHigh ?? max(heightByte, 32)

        return (
            image: image,
            hotspot: CGPoint(x: hotspotX, y: hotspotY),
            size: CGSize(width: width, height: height),
            delay: defaultDelay
        )
    }

    private func fourCC(_ data: Data, _ offset: Int) -> String {
        String(decoding: data[offset..<(offset + 4)], as: UTF8.self)
    }

    private func readUInt16LE(_ data: Data, _ offset: Int) -> UInt16 {
        data.withUnsafeBytes { rawBuffer in
            rawBuffer.baseAddress!.advanced(by: offset).loadUnaligned(as: UInt16.self).littleEndian
        }
    }

    private func readUInt32LE(_ data: Data, _ offset: Int) -> UInt32 {
        data.withUnsafeBytes { rawBuffer in
            rawBuffer.baseAddress!.advanced(by: offset).loadUnaligned(as: UInt32.self).littleEndian
        }
    }
}

struct ResolvedTheme {
    let filesByRole: [CursorRole: URL]
}

struct ThemeResolver {
    func resolveTheme(in directory: URL) throws -> ResolvedTheme {
        let candidates = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            .filter { ["ani", "cur"].contains($0.pathExtension.lowercased()) }
        guard !candidates.isEmpty else {
            throw CursorError.invalidThemeSelection("direct cursor files not found")
        }

        var mapping: [CursorRole: URL] = [:]
        for role in CursorRole.allCases {
            if let exact = candidates.first(where: { canonical($0.lastPathComponent) == canonical(role.themeFileName) }) {
                mapping[role] = exact
            }
        }
        return ResolvedTheme(filesByRole: mapping)
    }

    private func canonical(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping.lowercased()
    }
}

let defaults = UserDefaults(suiteName: "MacMouseCursor") ?? .standard
let folderPath = defaults.string(forKey: "selectedFolderPath") ?? ""
let overrideRaw = defaults.dictionary(forKey: "overridePaths") as? [String: String] ?? [:]
print("selectedFolderPath:", folderPath)
print("overridePaths:", overrideRaw)

let resolver = ThemeResolver()
let parser = AniParser()

guard !folderPath.isEmpty else {
    print("No selected folder.")
    exit(0)
}

let folderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
do {
    let resolved = try resolver.resolveTheme(in: folderURL)
    for role in CursorRole.allCases {
        if let override = overrideRaw[role.rawValue] {
            let url = URL(fileURLWithPath: override)
            do {
                let animation = try parser.parseCursorFile(at: url)
                print("override", role.rawValue, url.lastPathComponent, "frames", animation.frames.count, "size", Int(animation.canvasSize.width), "x", Int(animation.canvasSize.height))
            } catch {
                print("override FAILED", role.rawValue, url.lastPathComponent, error.localizedDescription)
            }
            continue
        }
        guard let url = resolved.filesByRole[role] else {
            print("missing", role.rawValue)
            continue
        }
        do {
            let animation = try parser.parseCursorFile(at: url)
            print("ok", role.rawValue, url.lastPathComponent, "frames", animation.frames.count, "size", Int(animation.canvasSize.width), "x", Int(animation.canvasSize.height))
        } catch {
            print("FAILED", role.rawValue, url.lastPathComponent, error.localizedDescription)
        }
    }
} catch {
    print("resolve failed:", error.localizedDescription)
}
