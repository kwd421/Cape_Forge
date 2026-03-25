import AppKit
import Foundation
import Testing
@testable import MacMouseCursor

struct ThemeResolverTests {
    @Test
    func resolvesDecomposedHangulFileNames() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("기본", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let decomposedName = "독케익_일반선택.ani"
        FileManager.default.createFile(atPath: folder.appendingPathComponent(decomposedName).path, contents: Data("x".utf8))

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == decomposedName)
    }

    @Test
    func rejectsPackRootWithoutDirectCursorFiles() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let nested = tempDirectory
            .appendingPathComponent("기본", isDirectory: true)
            .appendingPathComponent("테두리 O", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: nested.appendingPathComponent("독케익_일반선택.ani").path,
            contents: Data("x".utf8)
        )

        #expect(throws: CursorError.self) {
            try ThemeResolver().resolveTheme(in: tempDirectory)
        }
    }

    @Test
    func keepsExactRoleIsolationInsideLeafFolder() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("세트", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let files = [
            "독케익_일반선택.ani",
            "독케익_텍스트 선택.ani",
            "독케익_이동.ani"
        ]
        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow] != nil)
        #expect(resolved.filesByRole[.text] != nil)
        #expect(resolved.filesByRole[.move] != nil)
        #expect(resolved.filesByRole[.link] == nil)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

struct CursorMatcherTests {
    @MainActor
    @Test
    func selfTestMatchesRegisteredSystemCursors() {
        let results = CursorMatcher().runSelfTest()
        #expect(!results.isEmpty)
        #expect(results.filter { !$0.passed }.isEmpty)
    }
}

struct CapeExporterTests {
    @MainActor
    @Test
    func exportsCapeFileWithMousecapeKeys() throws {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 1, y: 1),
            canvasSize: CGSize(width: 16, height: 16)
        )
        let theme = CursorTheme(animations: [.arrow: animation])

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("cape")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try CapeExporter().exportCape(
            name: "Test Cape",
            author: "Tester",
            identifier: "local.test.cape",
            theme: theme,
            to: tempURL
        )

        let data = try Data(contentsOf: tempURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        let cursors = plist?["Cursors"] as? [String: Any]
        let arrow = cursors?["com.apple.coregraphics.Arrow"] as? [String: Any]

        #expect(plist?["CapeName"] as? String == "Test Cape")
        #expect(plist?["Identifier"] as? String == "local.test.cape")
        #expect(arrow?["FrameCount"] as? Int == 1)
        #expect((arrow?["Representations"] as? [Data])?.isEmpty == false)
    }
}
