import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: CursorController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mac Mouse Cursor")
                .font(.headline)

            Text(controller.selectedFolderURL?.lastPathComponent ?? "커서 폴더를 선택하세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Label(
                controller.selectedFolderIsValid
                    ? "\(controller.resolvedRoleCount)개 역할 준비됨"
                    : "폴더 확인 필요",
                systemImage: controller.selectedFolderIsValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.footnote)
            .foregroundStyle(controller.selectedFolderIsValid ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))

            Toggle("커서 오버레이 활성화", isOn: $controller.isEnabled)
            Toggle("로그인 시 실행", isOn: $controller.launchAtLogin)

            HStack(spacing: 8) {
                Button("설정 열기") {
                    (NSApp.delegate as? AppDelegate)?.openSettingsWindow()
                }
                Button("다시 불러오기") {
                    controller.reload()
                }
            }

            Divider()

            Text(controller.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("종료") {
                NSApp.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 280)
    }
}

struct SettingsView: View {
    @ObservedObject var controller: CursorController
    @State private var selection: CursorRole? = .arrow

    var body: some View {
        NavigationSplitView {
            List(CursorRole.allCases, selection: $selection) { role in
                if let assignment = controller.assignment(for: role) ?? controller.placeholderAssignment(for: role) {
                    CursorRoleRow(assignment: assignment)
                        .tag(role)
                }
            }
            .navigationTitle("커서")
            .frame(minWidth: 230)
        } detail: {
            if let role = selection, let assignment = controller.assignment(for: role) ?? controller.placeholderAssignment(for: role) {
                CursorRoleDetailView(controller: controller, assignment: assignment)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "cursorarrow")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("커서를 선택하세요")
                        .font(.headline)
                    Text("왼쪽 목록에서 역할을 고르면 상세 설정과 미리보기를 볼 수 있습니다.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 860, minHeight: 620)
    }
}

struct CursorRoleRow: View {
    let assignment: CursorAssignment

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusSymbolName)
                .foregroundStyle(statusColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.role.displayName)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var statusSymbolName: String {
        if !assignment.isResolved { return "exclamationmark.triangle.fill" }
        if assignment.isOverride { return "slider.horizontal.3" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if !assignment.isResolved { return .orange }
        if assignment.isOverride { return .accentColor }
        return .secondary
    }

    private var subtitle: String {
        if !assignment.isResolved { return "자동 매핑 실패" }
        if assignment.isOverride { return assignment.sourceURL?.lastPathComponent ?? "수동 지정" }
        return assignment.sourceURL?.lastPathComponent ?? "자동 매핑"
    }
}

struct CursorRoleDetailView: View {
    @ObservedObject var controller: CursorController
    let assignment: CursorAssignment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsHeader(controller: controller)

                VStack(alignment: .leading, spacing: 12) {
                    Text(assignment.role.displayName)
                        .font(.title2)
                    Text("기본 커서와 현재 적용 중인 커서를 비교하고, 필요하면 이 역할만 별도로 지정할 수 있습니다.")
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 20) {
                    PreviewGroup(
                        title: "기본 커서",
                        subtitle: "macOS 기본 포인터 모양",
                        animation: assignment.defaultPreview
                    )
                    PreviewGroup(
                        title: "적용 커서",
                        subtitle: assignment.sourceURL?.lastPathComponent ?? "폴더에서 자동 매핑된 파일",
                        animation: assignment.appliedPreview ?? assignment.defaultPreview
                    )
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        LabeledContent("역할") {
                            Text(assignment.role.displayName)
                        }
                        LabeledContent("자동 파일명") {
                            Text(assignment.role.themeFileName)
                                .textSelection(.enabled)
                        }
                        LabeledContent("현재 소스") {
                            Text(assignment.sourceURL?.path ?? "선택한 폴더 안에서 자동 매핑")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }
                        Divider()
                        HStack {
                            Button("커서 파일 변경…") {
                                controller.chooseOverride(for: assignment.role)
                            }
                            if assignment.sourceURL != nil {
                                Button("자동 매핑으로 되돌리기") {
                                    controller.clearOverride(for: assignment.role)
                                }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("할당")
                }

                CalibrationGroup(controller: controller, role: assignment.role)

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("현재 감지된 역할") {
                            Text(controller.currentObservation?.role.displayName ?? "아직 없음")
                        }
                        LabeledContent("핫스팟") {
                            if let observation = controller.currentObservation {
                                Text(String(format: "(%.1f, %.1f)", observation.hotspot.x, observation.hotspot.y))
                            } else {
                                Text("-")
                            }
                        }
                        LabeledContent("지문") {
                            Text(controller.currentObservation?.fingerprintPrefix ?? "-")
                                .monospaced()
                        }

                        if !controller.recentObservations.isEmpty {
                            Divider()
                            Text("최근 감지 기록")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(controller.recentObservations.prefix(8)) { observation in
                                    HStack {
                                        Text(observation.role.displayName)
                                        Spacer()
                                        Text(observation.timestamp, style: .time)
                                            .foregroundStyle(.secondary)
                                        Text(observation.fingerprintPrefix)
                                            .foregroundStyle(.secondary)
                                            .monospaced()
                                    }
                                    .font(.footnote)
                                }
                            }
                        }

                        if !controller.matcherSelfTestResults.isEmpty {
                            Divider()
                            Text("기본 커서 매처 자기검증")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(controller.matcherSelfTestResults) { result in
                                    HStack {
                                        Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(result.passed ? .green : .red)
                                        Text(result.name)
                                        Spacer()
                                        Text(result.observedRole.displayName)
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.footnote)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("감지 디버그")
                }

                Text(controller.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct CalibrationGroup: View {
    @ObservedObject var controller: CursorController
    let role: CursorRole

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("다른 앱이나 창에서 커스텀 커서가 실제 포인터보다 어긋나 보이면 여기서 보정할 수 있습니다.")
                    .foregroundStyle(.secondary)

                HStack {
                    Button("자동 보정") {
                        _ = controller.autoCalibrate(for: role)
                    }
                    Spacer()
                }

                CalibrationSliderRow(
                    title: "가로 보정",
                    value: Binding(
                        get: { controller.calibration(for: role).offsetX },
                        set: { controller.setCalibrationX($0, for: role) }
                    ),
                    range: -40...40
                )

                CalibrationSliderRow(
                    title: "세로 보정",
                    value: Binding(
                        get: { controller.calibration(for: role).offsetY },
                        set: { controller.setCalibrationY($0, for: role) }
                    ),
                    range: -40...40
                )

                HStack {
                    let calibration = controller.calibration(for: role)
                    Text("현재 보정값: X \(Int(calibration.offsetX)), Y \(Int(calibration.offsetY))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("보정 초기화") {
                        controller.resetCalibration(for: role)
                    }
                    .disabled(calibration == .zero)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("위치 보정")
        }
    }
}

struct CalibrationSliderRow: View {
    let title: String
    let value: Binding<Double>
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.0f pt", value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(value: value, in: range, step: 1)
        }
    }
}

struct SettingsHeader: View {
    @ObservedObject var controller: CursorController

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("커서 폴더")
                            .font(.headline)
                        Text(controller.selectedFolderURL?.path ?? "선택된 폴더 없음")
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button("폴더 선택…") {
                        controller.chooseThemeFolder()
                    }
                }

                HStack(spacing: 12) {
                    Label(
                        controller.selectedFolderIsValid
                            ? "\(controller.resolvedRoleCount)개 역할을 사용할 수 있습니다"
                            : "선택한 폴더를 확인해야 합니다",
                        systemImage: controller.selectedFolderIsValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(controller.selectedFolderIsValid ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))

                    if controller.selectedFolderIsValid {
                        Text("자동 매핑 후 필요한 역할만 개별적으로 재지정할 수 있습니다.")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.footnote)

                HStack(spacing: 18) {
                    Toggle("커서 오버레이 활성화", isOn: $controller.isEnabled)
                    Toggle("로그인 시 실행", isOn: $controller.launchAtLogin)
                    Spacer()
                    Button("Mousecape로 내보내기…") {
                        controller.exportMousecapeCape()
                    }
                    Button("다시 불러오기") {
                        controller.reload()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PreviewGroup: View {
    let title: String
    let subtitle: String
    let animation: CursorAnimation

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                CursorPreviewView(animation: animation)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        } label: {
            Text(title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CursorPreviewView: View {
    let animation: CursorAnimation

    var body: some View {
        TimelineView(.animation) { context in
            let index = currentIndex(at: context.date)
            Image(nsImage: animation.frames[index].image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .padding(24)
        }
    }

    private func currentIndex(at date: Date) -> Int {
        guard animation.frames.count > 1 else { return 0 }
        let total = animation.frames.reduce(0.0) { $0 + $1.delay }
        guard total > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: total)
        var running = 0.0
        for (index, frame) in animation.frames.enumerated() {
            running += frame.delay
            if elapsed < running {
                return index
            }
        }
        return animation.frames.count - 1
    }
}
