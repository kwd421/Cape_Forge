import Foundation

struct LaunchAgentManager {
    private let identifier = "com.seinel.capeforge"

    func setEnabled(_ enabled: Bool) throws {
        let launchAgents = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
        try FileManager.default.createDirectory(at: launchAgents, withIntermediateDirectories: true)

        let plistURL = launchAgents.appendingPathComponent("\(identifier).plist")
        if enabled {
            let executable = try launchExecutablePath()
            let plist: [String: Any] = [
                "Label": identifier,
                "ProgramArguments": [executable],
                "RunAtLoad": true,
                "KeepAlive": false,
                "ProcessType": "Interactive"
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: plistURL, options: .atomic)
            try reloadLaunchAgent(at: plistURL, load: true)
        } else if FileManager.default.fileExists(atPath: plistURL.path) {
            try reloadLaunchAgent(at: plistURL, load: false)
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    private func reloadLaunchAgent(at plistURL: URL, load: Bool) throws {
        try runLaunchctl(arguments: ["bootout", "gui/\(uid())", plistURL.path], allowFailure: true)
        guard load else { return }
        try runLaunchctl(arguments: ["bootstrap", "gui/\(uid())", plistURL.path], allowFailure: false)
    }

    private func runLaunchctl(arguments: [String], allowFailure: Bool) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 && !allowFailure {
            let message = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw CursorError.launchAgentUpdateFailed(message ?? "launchctl exited with status \(process.terminationStatus)")
        }
    }

    private func uid() -> String {
        String(getuid())
    }

    private func launchExecutablePath() throws -> String {
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension == "app" else {
            throw CursorError.launchAgentUpdateFailed(
                "개발 빌드에서는 로그인 시 실행을 지원하지 않습니다. 패키징된 .app을 실행한 뒤 다시 켜세요."
            )
        }

        guard let executable = Bundle.main.executableURL?.path else {
            throw CursorError.launchAgentUpdateFailed("앱 실행 파일 경로를 찾지 못했습니다.")
        }
        return executable
    }
}
