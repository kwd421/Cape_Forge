import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case korean
    case english

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .korean: return "menu.language.korean"
        case .english: return "menu.language.english"
        }
    }
}

final class LocalizationController: ObservableObject {
    nonisolated(unsafe) static let shared = LocalizationController()

    @Published private(set) var selectedLanguage: AppLanguage?

    private let defaultsKey = "appLanguageOverride"

    private init() {
        let storedValue = UserDefaults.standard.string(forKey: defaultsKey)
        selectedLanguage = AppLanguage(rawValue: storedValue ?? "")
    }

    func setLanguage(_ language: AppLanguage) {
        guard selectedLanguage != language else { return }
        selectedLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: defaultsKey)
    }
}

enum Localized {
    static func string(_ key: String) -> String {
        activeTable[key] ?? english[key] ?? key
    }

    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }

    private static var activeTable: [String: String] {
        let language: String
        switch LocalizationController.shared.selectedLanguage {
        case .korean?:
            language = "ko"
        case .english?:
            language = "en"
        case nil:
            language = Locale.preferredLanguages.first?.lowercased() ?? "en"
        }
        return language.hasPrefix("ko") ? korean : english
    }

    private static let english: [String: String] = [
        "app.chooseCursorFolder": "Choose a cursor folder",
        "app.rolesReady": "%d roles ready",
        "app.folderRequired": "Folder required",
        "app.openSettings": "Open Settings",
        "app.quit": "Quit",
        "app.cursors": "Cursors",
        "app.noCursorLoaded": "No cursor loaded",
        "app.loadCursorFolderHint": "Load a cursor folder, then choose a role from the list to preview it.",
        "app.exportToMousecape": "Export to Mousecape…",
        "app.automaticMatchFailed": "Automatic matching failed",
        "app.automaticMatchFailedArrowFallback": "Automatic matching failed · using arrow fallback",
        "app.manualOverride": "Manual override",
        "app.automaticallyMatched": "Automatically matched",
        "app.automaticallyMatchedFromFolder": "Automatically matched from the folder",
        "app.changeCursorFile": "Change Cursor File…",
        "app.arrowFallbackDescription": "A dedicated cursor for this role was not found, so the theme's arrow cursor is being used instead.",
        "app.role": "Role",
        "app.mousecape": "Mousecape",
        "app.currentSource": "Current Source",
        "app.automaticallyMatchedInsideSelectedFolder": "Automatically matched inside the selected folder",
        "app.status": "Status",
        "app.automaticMatchFailedArrowFallbackShort": "Automatic matching failed (using arrow fallback)",
        "app.cursorFolder": "Cursor Folder",
        "app.noFolderSelected": "No folder selected",
        "app.chooseFolder": "Choose Folder…",
        "app.cursorWillAppearHere": "The cursor will appear here after you load one.",
        "role.arrow": "Arrow",
        "role.text": "Text Selection",
        "role.link": "Link Selection",
        "role.location": "Drag",
        "role.precision": "Precision Selection",
        "role.move": "Move",
        "role.unavailable": "Unavailable",
        "role.busy": "Busy",
        "role.working": "Wait",
        "role.help": "Help",
        "role.handwriting": "Handwriting",
        "role.person": "Cell Selection",
        "role.alternate": "Alias",
        "role.verticalResize": "Vertical Resize",
        "role.horizontalResize": "Horizontal Resize",
        "role.diagonalResizeNWSE": "Diagonal Resize 1",
        "role.diagonalResizeNESW": "Diagonal Resize 2",
        "status.startingUp": "Starting up...",
        "status.chooseCursorFolder": "Choose a cursor folder.",
        "status.supportedFiles": "Supported files are .ani and .cur.",
        "status.exportSuccess": "Exported Mousecape cape: %@",
        "status.exportFailure": "Cape export failed: %@",
        "status.loaded": "Loaded %@ · %d/%d roles mapped",
        "status.loadFailure": "Load failed: %@",
        "panel.chooseFolder": "Choose Folder",
        "panel.chooseCursor": "Choose Cursor",
        "panel.export": "Export",
        "menu.language": "Language",
        "menu.language.korean": "Korean",
        "menu.language.english": "English",
        "error.noThemeFolderSelected": "No theme folder is selected.",
        "error.themeFileMissing": "Theme file is missing: %@",
        "error.aniParsingFailed": "ANI parsing failed: %@",
        "error.unsupportedCursorPayload": "The cursor frame could not be read as an image.",
        "error.invalidThemeSelection.noCursorFiles": "This folder does not contain cursor files that can be used directly.\nChoose a folder that contains .ani or .cur files at the top level.",
        "error.unsupportedExtension": "Unsupported file extension: %@",
        "error.invalidRiffAconHeader": "The file does not have a RIFF ACON header.",
        "error.invalidChunkLength": "The chunk length is invalid.",
        "error.noFrames": "The file does not contain any frames.",
        "error.invalidIconChunkLength": "The icon chunk length is invalid.",
        "error.curTooShort": "The CUR data is too short.",
        "error.invalidCurHeader": "The file does not contain a valid CUR header.",
        "error.invalidCurEmbeddedRange": "The embedded CUR image range is invalid.",
        "error.noCursorsToExport": "There are no cursors to export."
    ]

    private static let korean: [String: String] = [
        "app.chooseCursorFolder": "커서 폴더를 선택하세요",
        "app.rolesReady": "%d개 역할 준비됨",
        "app.folderRequired": "폴더 확인 필요",
        "app.openSettings": "설정 열기",
        "app.quit": "종료",
        "app.cursors": "커서",
        "app.noCursorLoaded": "불러온 커서가 없습니다",
        "app.loadCursorFolderHint": "커서 폴더를 불러온 뒤 왼쪽 목록에서 역할을 고르면 해당 커서를 표시합니다.",
        "app.exportToMousecape": "Mousecape로 내보내기…",
        "app.automaticMatchFailed": "자동 매핑 실패",
        "app.automaticMatchFailedArrowFallback": "자동 매핑 실패 · 일반 커서 대체",
        "app.manualOverride": "수동 지정",
        "app.automaticallyMatched": "자동 매핑",
        "app.automaticallyMatchedFromFolder": "폴더에서 자동 매핑된 파일",
        "app.changeCursorFile": "커서 파일 변경…",
        "app.arrowFallbackDescription": "자동 매칭되는 전용 커서를 찾지 못해 이 테마의 일반 커서로 대체했습니다.",
        "app.role": "역할",
        "app.mousecape": "Mousecape",
        "app.currentSource": "현재 소스",
        "app.automaticallyMatchedInsideSelectedFolder": "선택한 폴더 안에서 자동 매핑",
        "app.status": "상태",
        "app.automaticMatchFailedArrowFallbackShort": "자동 매핑 실패 (일반 커서 대체)",
        "app.cursorFolder": "커서 폴더",
        "app.noFolderSelected": "선택된 폴더 없음",
        "app.chooseFolder": "폴더 선택…",
        "app.cursorWillAppearHere": "커서를 불러오면 여기에 표시됩니다.",
        "role.arrow": "일반 선택",
        "role.text": "텍스트 선택",
        "role.link": "링크 선택",
        "role.location": "드래그",
        "role.precision": "정밀도 선택",
        "role.move": "이동",
        "role.unavailable": "사용 불가",
        "role.busy": "사용 중",
        "role.working": "대기",
        "role.help": "도움말",
        "role.handwriting": "손글씨",
        "role.person": "셀 선택",
        "role.alternate": "바로가기",
        "role.verticalResize": "수직 크기 조절",
        "role.horizontalResize": "수평 크기 조절",
        "role.diagonalResizeNWSE": "대각선 크기 조절 1",
        "role.diagonalResizeNESW": "대각선 크기 조절 2",
        "status.startingUp": "초기화 중...",
        "status.chooseCursorFolder": "커서 폴더를 선택하세요.",
        "status.supportedFiles": "지원하는 파일은 .ani 또는 .cur 입니다.",
        "status.exportSuccess": "Mousecape용 cape 내보내기 완료: %@",
        "status.exportFailure": "cape 내보내기 실패: %@",
        "status.loaded": "로드 완료: %@ · %d/%d개 역할 연결됨",
        "status.loadFailure": "불러오기 실패: %@",
        "panel.chooseFolder": "폴더 선택",
        "panel.chooseCursor": "커서 선택",
        "panel.export": "내보내기",
        "menu.language": "언어",
        "menu.language.korean": "한국어",
        "menu.language.english": "영어",
        "error.noThemeFolderSelected": "테마 폴더가 선택되지 않았습니다.",
        "error.themeFileMissing": "테마 파일이 없습니다: %@",
        "error.aniParsingFailed": "ANI 파싱 실패: %@",
        "error.unsupportedCursorPayload": "커서 프레임을 이미지로 읽지 못했습니다.",
        "error.invalidThemeSelection.noCursorFiles": "이 폴더에는 바로 적용할 커서 파일이 없습니다.\n.ani 또는 .cur 파일이 직접 들어 있는 폴더를 선택하세요.",
        "error.unsupportedExtension": "지원하지 않는 확장자입니다: %@",
        "error.invalidRiffAconHeader": "RIFF ACON 헤더가 아닙니다.",
        "error.invalidChunkLength": "청크 길이가 잘못되었습니다.",
        "error.noFrames": "프레임이 없습니다.",
        "error.invalidIconChunkLength": "icon 청크 길이가 잘못되었습니다.",
        "error.curTooShort": "CUR 데이터가 너무 짧습니다.",
        "error.invalidCurHeader": "CUR 헤더가 아닙니다.",
        "error.invalidCurEmbeddedRange": "CUR 내부 이미지 범위가 잘못되었습니다.",
        "error.noCursorsToExport": "내보낼 커서가 없습니다."
    ]
}
