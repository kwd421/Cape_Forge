import AppKit
import Combine
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

enum CursorRole: String, CaseIterable, Identifiable {
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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arrow:
            return "일반 선택"
        case .text:
            return "텍스트 선택"
        case .link:
            return "링크 선택"
        case .precision:
            return "정밀도 선택"
        case .move:
            return "이동"
        case .unavailable:
            return "사용 불가"
        case .busy:
            return "백그라운드 작업"
        case .verticalResize:
            return "수직 크기 조절"
        case .horizontalResize:
            return "수평 크기 조절"
        case .diagonalResizeNWSE:
            return "대각선 크기 조절 1"
        case .diagonalResizeNESW:
            return "대각선 크기 조절 2"
        }
    }

    var themeFileName: String {
        switch self {
        case .arrow:
            return "독케익_일반선택.ani"
        case .text:
            return "독케익_텍스트 선택.ani"
        case .link:
            return "독케익_연결,위치,사용자 선택.ani"
        case .precision:
            return "독케익_정밀도 선택.ani"
        case .move:
            return "독케익_이동.ani"
        case .unavailable:
            return "독케익_사용할 수 없음.ani"
        case .busy:
            return "독케익_백그라운드 작업,사용중.ani"
        case .verticalResize:
            return "독케익_수직 크기 조절.ani"
        case .horizontalResize:
            return "독케익_수평 크기 조절.ani"
        case .diagonalResizeNWSE:
            return "독케익_대각선 방향 크기 조절 1.ani"
        case .diagonalResizeNESW:
            return "독케익_대각선 방향 크기 조절 2.ani"
        }
    }
}

struct CursorAssignment: Identifiable {
    let role: CursorRole
    let defaultPreview: CursorAnimation
    let appliedPreview: CursorAnimation?
    let sourceURL: URL?
    let isOverride: Bool
    let isResolved: Bool

    var id: CursorRole { role }
}

struct CursorTheme {
    let animations: [CursorRole: CursorAnimation]

    subscript(role: CursorRole) -> CursorAnimation? {
        animations[role]
    }
}

struct CursorCalibration: Equatable {
    var offsetX: Double = 0
    var offsetY: Double = 0

    static let zero = CursorCalibration()
}

private struct OpaqueBounds {
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int

    var centerX: Double { Double(minX + maxX) / 2.0 }
    var centerY: Double { Double(minY + maxY) / 2.0 }
}

@MainActor
final class CursorController: ObservableObject {
    @Published private(set) var currentObservation: CursorObservation?
    @Published private(set) var recentObservations: [CursorObservation] = []
    @Published private(set) var matcherSelfTestResults: [CursorMatcherSelfTestResult] = []
    @Published var isEnabled = true {
        didSet {
            defaults.set(isEnabled, forKey: Keys.isEnabled)
            updateRunningState()
        }
    }
    @Published var launchAtLogin = false {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            do {
                try launchAgentManager.setEnabled(launchAtLogin)
                statusText = launchAtLogin ? "로그인 시 실행을 켰습니다." : "로그인 시 실행을 껐습니다."
            } catch {
                statusText = "로그인 항목 설정 실패: \(error.localizedDescription)"
            }
        }
    }
    @Published private(set) var selectedFolderURL: URL?
    @Published private(set) var selectedFolderIsValid = false
    @Published private(set) var resolvedRoleCount = 0
    @Published private(set) var assignments: [CursorAssignment] = []
    @Published private(set) var calibrations: [CursorRole: CursorCalibration] = [:]
    @Published private(set) var statusText = "초기화 중..."

    private let defaults = UserDefaults.standard
    private let overlay = CursorOverlayWindowController()
    private let parser = AniParser()
    private let capeExporter = CapeExporter()
    private let launchAgentManager = LaunchAgentManager()
    private let cursorMatcher = CursorMatcher()
    private let themeResolver = ThemeResolver()
    private var overrideURLs: [CursorRole: URL] = [:]
    private let debugEnabled = ProcessInfo.processInfo.environment["MAC_MOUSE_CURSOR_DEBUG"] == "1"

    init() {
        overlay.onObservationChanged = { [weak self] observation in
            self?.record(observation: observation)
        }
    }

    func start() {
        assignments = unresolvedAssignments()
        if let folderPath = defaults.string(forKey: Keys.folderPath) {
            selectedFolderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
        }
        overrideURLs = loadOverrides()
        calibrations = loadCalibrations()
        matcherSelfTestResults = cursorMatcher.runSelfTest()
        isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        reload()
    }

    func stop() {
        overlay.stop()
    }

    func chooseThemeFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = selectedFolderURL
        panel.prompt = "폴더 선택"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        setThemeFolder(url)
    }

    func setThemeFolder(_ url: URL) {
        selectedFolderURL = url
        defaults.set(url.path, forKey: Keys.folderPath)
        reload()
    }

    func chooseOverride(for role: CursorRole) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.data]
        panel.directoryURL = overrideURLs[role]?.deletingLastPathComponent() ?? selectedFolderURL
        panel.prompt = "커서 선택"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let ext = url.pathExtension.lowercased()
        guard ext == "ani" || ext == "cur" else {
            statusText = "지원하는 파일은 .ani 또는 .cur 입니다."
            return
        }
        overrideURLs[role] = url
        saveOverrides()
        reload()
    }

    func clearOverride(for role: CursorRole) {
        overrideURLs.removeValue(forKey: role)
        saveOverrides()
        reload()
    }

    func exportMousecapeCape() {
        do {
            let resolution = try loadTheme()
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.data]
            panel.nameFieldStringValue = sanitizedCapeFileName()
            panel.canCreateDirectories = true
            panel.prompt = "내보내기"

            guard panel.runModal() == .OK, var url = panel.url else { return }
            if url.pathExtension.lowercased() != "cape" {
                url.deletePathExtension()
                url.appendPathExtension("cape")
            }

            try capeExporter.exportCape(
                name: capeDisplayName(),
                author: NSFullUserName().isEmpty ? NSUserName() : NSFullUserName(),
                identifier: "local.\(Bundle.main.bundleIdentifier ?? "macmousecursor").\(UUID().uuidString.lowercased())",
                theme: resolution.theme,
                to: url
            )
            statusText = "Mousecape용 cape 내보내기 완료: \(url.lastPathComponent)"
        } catch {
            statusText = "cape 내보내기 실패: \(error.localizedDescription)"
        }
    }

    func calibration(for role: CursorRole) -> CursorCalibration {
        calibrations[role] ?? .zero
    }

    func setCalibration(_ calibration: CursorCalibration, for role: CursorRole) {
        if calibration == .zero {
            calibrations.removeValue(forKey: role)
        } else {
            calibrations[role] = calibration
        }
        saveCalibrations()
        overlay.setCalibrations(calibrations)
    }

    func resetCalibration(for role: CursorRole) {
        setCalibration(.zero, for: role)
    }

    func setCalibrationX(_ value: Double, for role: CursorRole) {
        var calibration = calibration(for: role)
        calibration.offsetX = value
        setCalibration(calibration, for: role)
    }

    func setCalibrationY(_ value: Double, for role: CursorRole) {
        var calibration = calibration(for: role)
        calibration.offsetY = value
        setCalibration(calibration, for: role)
    }

    @discardableResult
    func autoCalibrate(for role: CursorRole) -> CursorCalibration? {
        guard
            let assignment = assignment(for: role),
            let applied = assignment.appliedPreview,
            let defaultBounds = opaqueBounds(for: assignment.defaultPreview.frames[0].image),
            let appliedBounds = opaqueBounds(for: applied.frames[0].image)
        else {
            statusText = "자동 보정 실패: 기준 이미지를 읽지 못했습니다."
            return nil
        }

        let defaultAnchor = anchorPoint(for: role, bounds: defaultBounds)
        let appliedAnchor = anchorPoint(for: role, bounds: appliedBounds)

        let defaultDeltaX = defaultAnchor.x - assignment.defaultPreview.hotspot.x
        let defaultDeltaY = defaultAnchor.y - assignment.defaultPreview.hotspot.y
        let appliedDeltaX = appliedAnchor.x - applied.hotspot.x
        let appliedDeltaY = appliedAnchor.y - applied.hotspot.y

        let calibration = CursorCalibration(
            offsetX: defaultDeltaX - appliedDeltaX,
            offsetY: defaultDeltaY - appliedDeltaY
        )

        setCalibration(calibration, for: role)
        statusText = "자동 보정 적용: \(role.displayName) · X \(Int(calibration.offsetX)), Y \(Int(calibration.offsetY))"
        return calibration
    }

    func reload() {
        do {
            let resolution = try loadTheme()
            let theme = resolution.theme
            overlay.setTheme(theme, matcher: cursorMatcher)
            overlay.setCalibrations(calibrations)
            assignments = makeAssignments(from: theme, resolvedFiles: resolution.filesByRole)
            resolvedRoleCount = assignments.filter(\.isResolved).count
            selectedFolderIsValid = true
            let folderName = selectedFolderURL?.lastPathComponent ?? "폴더 없음"
            statusText = "로드 완료: \(folderName) · \(resolvedRoleCount)/\(CursorRole.allCases.count)개 역할 연결됨"
            updateRunningState()
        } catch {
            overlay.stop()
            assignments = unresolvedAssignments()
            resolvedRoleCount = 0
            selectedFolderIsValid = false
            statusText = "불러오기 실패: \(error.localizedDescription)"
        }
    }

    func assignment(for role: CursorRole) -> CursorAssignment? {
        assignments.first(where: { $0.role == role })
    }

    func placeholderAssignment(for role: CursorRole) -> CursorAssignment? {
        unresolvedAssignments().first(where: { $0.role == role })
    }

    private func record(observation: CursorObservation) {
        if debugEnabled {
            NSLog(
                "MacMouseCursor roleChanged=%@ hotSpot=(%.1f, %.1f) fingerprint=%@",
                observation.role.rawValue,
                observation.hotspot.x,
                observation.hotspot.y,
                observation.fingerprintPrefix
            )
        }
        currentObservation = observation
        recentObservations.insert(observation, at: 0)
        if recentObservations.count > 20 {
            recentObservations.removeLast(recentObservations.count - 20)
        }
    }

    private func updateRunningState() {
        guard isEnabled else {
            overlay.stop()
            return
        }
        overlay.start()
    }

    private func loadTheme() throws -> (theme: CursorTheme, filesByRole: [CursorRole: URL]) {
        guard let baseDirectory = selectedFolderURL else {
            throw CursorError.missingTheme("테마 폴더가 선택되지 않았습니다.")
        }
        var animations: [CursorRole: CursorAnimation] = [:]
        var resolvedFiles = try themeResolver.resolveTheme(in: baseDirectory).filesByRole

        for role in CursorRole.allCases {
            if let override = overrideURLs[role], FileManager.default.fileExists(atPath: override.path) {
                animations[role] = try parser.parseCursorFile(at: override)
                resolvedFiles[role] = override
                continue
            }
            guard let url = resolvedFiles[role] else { continue }
            animations[role] = try parser.parseCursorFile(at: url)
        }

        guard animations[.arrow] != nil else {
            throw CursorError.missingTheme(baseDirectory.path)
        }

        return (CursorTheme(animations: animations), resolvedFiles)
    }

    private func makeAssignments(from theme: CursorTheme, resolvedFiles: [CursorRole: URL]) -> [CursorAssignment] {
        CursorRole.allCases.map { role in
            let isOverride = overrideURLs[role] != nil
            let applied = theme[role]
            return CursorAssignment(
                role: role,
                defaultPreview: cursorMatcher.defaultPreview(for: role),
                appliedPreview: applied,
                sourceURL: resolvedFiles[role],
                isOverride: isOverride,
                isResolved: applied != nil
            )
        }
    }

    private func unresolvedAssignments() -> [CursorAssignment] {
        CursorRole.allCases.map { role in
            CursorAssignment(
                role: role,
                defaultPreview: cursorMatcher.defaultPreview(for: role),
                appliedPreview: nil,
                sourceURL: overrideURLs[role],
                isOverride: overrideURLs[role] != nil,
                isResolved: false
            )
        }
    }

    private func loadOverrides() -> [CursorRole: URL] {
        guard let raw = defaults.dictionary(forKey: Keys.overrides) as? [String: String] else { return [:] }
        var result: [CursorRole: URL] = [:]
        for (key, path) in raw {
            guard let role = CursorRole(rawValue: key) else { continue }
            result[role] = URL(fileURLWithPath: path)
        }
        return result
    }

    private func saveOverrides() {
        let raw = Dictionary(uniqueKeysWithValues: overrideURLs.map { ($0.key.rawValue, $0.value.path) })
        defaults.set(raw, forKey: Keys.overrides)
    }

    private func capeDisplayName() -> String {
        selectedFolderURL?.lastPathComponent.isEmpty == false ? selectedFolderURL!.lastPathComponent : "Mac Mouse Cursor Export"
    }

    private func sanitizedCapeFileName() -> String {
        let raw = capeDisplayName()
        let invalid = CharacterSet(charactersIn: "/:\\")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "MacMouseCursor.cape" : "\(cleaned).cape"
    }

    private func opaqueBounds(for image: NSImage) -> OpaqueBounds? {
        guard let rep = bitmapRep(for: image) else { return nil }

        var minX = rep.pixelsWide
        var minY = rep.pixelsHigh
        var maxX = -1
        var maxY = -1

        for y in 0..<rep.pixelsHigh {
            for x in 0..<rep.pixelsWide {
                guard let color = rep.colorAt(x: x, y: y) else { continue }
                if color.alphaComponent > 0.05 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard maxX >= minX, maxY >= minY else { return nil }
        return OpaqueBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }

    private func bitmapRep(for image: NSImage) -> NSBitmapImageRep? {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).max(by: {
            ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
        }) {
            return rep
        }

        let size = image.size == .zero ? NSSize(width: 32, height: 32) : image.size
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: max(Int(size.width.rounded(.up)), 1),
                pixelsHigh: max(Int(size.height.rounded(.up)), 1),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    private func anchorPoint(for role: CursorRole, bounds: OpaqueBounds) -> CGPoint {
        switch role {
        case .arrow, .link, .move, .unavailable, .busy:
            return CGPoint(x: Double(bounds.minX), y: Double(bounds.maxY))
        case .text:
            return CGPoint(x: bounds.centerX, y: Double(bounds.maxY))
        case .precision:
            return CGPoint(x: bounds.centerX, y: bounds.centerY)
        case .verticalResize:
            return CGPoint(x: bounds.centerX, y: bounds.centerY)
        case .horizontalResize:
            return CGPoint(x: bounds.centerX, y: bounds.centerY)
        case .diagonalResizeNWSE, .diagonalResizeNESW:
            return CGPoint(x: bounds.centerX, y: bounds.centerY)
        }
    }

    private func loadCalibrations() -> [CursorRole: CursorCalibration] {
        guard let raw = defaults.dictionary(forKey: Keys.calibrations) as? [String: [String: Double]] else {
            return [:]
        }

        var result: [CursorRole: CursorCalibration] = [:]
        for (key, payload) in raw {
            guard let role = CursorRole(rawValue: key) else { continue }
            result[role] = CursorCalibration(
                offsetX: payload["x"] ?? 0,
                offsetY: payload["y"] ?? 0
            )
        }
        return result
    }

    private func saveCalibrations() {
        let raw = Dictionary(uniqueKeysWithValues: calibrations.map { role, calibration in
            (
                role.rawValue,
                [
                    "x": calibration.offsetX,
                    "y": calibration.offsetY
                ]
            )
        })
        defaults.set(raw, forKey: Keys.calibrations)
    }

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let folderPath = "selectedFolderPath"
        static let overrides = "overridePaths"
        static let calibrations = "calibrationOffsets"
        static let launchAtLogin = "launchAtLogin"
    }
}

enum CursorError: LocalizedError {
    case missingTheme(String)
    case invalidANI(String)
    case invalidThemeSelection(String)
    case launchAgentUpdateFailed(String)
    case unsupportedCursorPayload

    var errorDescription: String? {
        switch self {
        case .missingTheme(let path):
            return "테마 파일이 없습니다: \(path)"
        case .invalidANI(let message):
            return "ANI 파싱 실패: \(message)"
        case .invalidThemeSelection(let message):
            return message
        case .launchAgentUpdateFailed(let message):
            return "로그인 항목을 적용하지 못했습니다: \(message)"
        case .unsupportedCursorPayload:
            return "커서 프레임을 이미지로 읽지 못했습니다."
        }
    }
}
