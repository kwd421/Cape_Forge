import Foundation

struct ResolvedTheme {
    let filesByRole: [CursorRole: URL]
}

struct ThemeResolver {
    func resolveTheme(in directory: URL) throws -> ResolvedTheme {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw CursorError.missingTheme(directory.path)
        }

        let candidates = try directCursorFiles(in: directory)
        guard !candidates.isEmpty else {
            throw CursorError.invalidThemeSelection("""
            이 폴더에는 바로 적용할 커서 파일이 없습니다.
            .ani 또는 .cur 파일이 직접 들어 있는 폴더를 선택하세요.
            """)
        }

        var mapping: [CursorRole: URL] = [:]

        for role in CursorRole.allCases {
            if let exact = candidates.first(where: { canonicalFileName($0.lastPathComponent) == canonicalFileName(role.themeFileName) }) {
                mapping[role] = exact
                continue
            }

            let fuzzyMatches = candidates
                .map { ($0, fuzzyScore(for: role, candidate: $0)) }
                .filter { $0.1 > 0 }
                .sorted {
                    if $0.1 == $1.1 {
                        return canonicalStem($0.0) < canonicalStem($1.0)
                    }
                    return $0.1 > $1.1
                }

            if let best = fuzzyMatches.first?.0 {
                mapping[role] = best
            }
        }

        return ResolvedTheme(filesByRole: mapping)
    }

    private func directCursorFiles(in directory: URL) throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return contents.filter {
            ["ani", "cur"].contains($0.pathExtension.lowercased())
        }
    }

    private func fuzzyScore(for role: CursorRole, candidate: URL) -> Int {
        let name = canonicalStem(candidate)

        let keywords: [CursorRole: [String]] = [
            .arrow: ["일반선택", "일반", "기본선택", "arrow"],
            .text: ["텍스트선택", "텍스트", "text", "ibeam"],
            .link: ["연결", "위치", "사용자선택", "링크", "link", "pointinghand"],
            .precision: ["정밀도선택", "정밀도", "crosshair"],
            .move: ["이동", "move", "openhand", "closedhand"],
            .unavailable: ["사용할수없음", "사용불가", "notallowed", "unavailable"],
            .busy: ["백그라운드작업", "사용중", "busy", "working"],
            .verticalResize: ["수직크기조절", "vertical", "updown"],
            .horizontalResize: ["수평크기조절", "horizontal", "leftright"],
            .diagonalResizeNWSE: ["대각선방향크기조절1", "대각선1", "nwse"],
            .diagonalResizeNESW: ["대각선방향크기조절2", "대각선2", "nesw"]
        ]

        return keywords[role, default: []].reduce(into: 0) { score, keyword in
            if name.contains(keyword) {
                score += 1
            }
        }
    }

    private func canonicalFileName(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping.lowercased()
    }

    private func canonicalStem(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
            .precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: "독케익_", with: "")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
