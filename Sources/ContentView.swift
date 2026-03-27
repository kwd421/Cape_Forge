import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        VStack(alignment: .leading, spacing: 14) {
            Text("Cape Forge")
                .font(.headline)

            Text(controller.selectedFolderURL?.lastPathComponent ?? Localized.string("app.chooseCursorFolder"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Label(
                controller.selectedFolderIsValid
                    ? Localized.string("app.rolesReady", controller.resolvedRoleCount)
                    : Localized.string("app.folderRequired"),
                systemImage: controller.selectedFolderIsValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.footnote)
            .foregroundStyle(controller.selectedFolderIsValid ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))

            HStack(spacing: 8) {
                Button(Localized.string("app.openSettings")) {
                    (NSApp.delegate as? AppDelegate)?.openSettingsWindow()
                }
            }

            Divider()

            Text(controller.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(Localized.string("app.quit")) {
                NSApp.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 280)
    }
}

struct SettingsView: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared
    @State private var selection: CursorRole? = .arrow

    var body: some View {
        let _ = localization.selectedLanguage
        VStack(spacing: 0) {
            NavigationSplitView {
                List(CursorRole.allCases, selection: $selection) { role in
                    if let assignment = controller.assignment(for: role) {
                        CursorRoleRow(assignment: assignment)
                            .tag(role)
                    }
                }
                .navigationTitle(Localized.string("app.cursors"))
                .frame(minWidth: 230)
            } detail: {
                if let role = selection, let assignment = controller.assignment(for: role) {
                    CursorRoleDetailView(controller: controller, assignment: assignment)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "cursorarrow")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                        Text(Localized.string("app.noCursorLoaded"))
                            .font(.headline)
                        Text(Localized.string("app.loadCursorFolderHint"))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            Divider()
            HStack {
                Spacer()
                Button(Localized.string("app.exportToMousecape")) {
                    controller.exportMousecapeCape()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(minWidth: 860, minHeight: 620)
    }
}

struct CursorRoleRow: View {
    let assignment: CursorAssignment
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
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
        if assignment.usesArrowFallback { return "exclamationmark.triangle.fill" }
        if assignment.isOverride { return "slider.horizontal.3" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if !assignment.isResolved { return .orange }
        if assignment.usesArrowFallback { return .orange }
        if assignment.isOverride { return .accentColor }
        return .secondary
    }

    private var subtitle: String {
        if !assignment.isResolved { return Localized.string("app.automaticMatchFailed") }
        if assignment.usesArrowFallback { return Localized.string("app.automaticMatchFailedArrowFallback") }
        if assignment.isOverride { return assignment.sourceURL?.lastPathComponent ?? Localized.string("app.manualOverride") }
        return assignment.sourceURL?.lastPathComponent ?? Localized.string("app.automaticallyMatched")
    }
}

struct CursorRoleDetailView: View {
    @ObservedObject var controller: CursorController
    let assignment: CursorAssignment
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsHeader(controller: controller)

                if let appliedPreview = assignment.appliedPreview {
                    PreviewGroup(
                        subtitle: assignment.sourceURL?.lastPathComponent ?? Localized.string("app.automaticallyMatchedFromFolder"),
                        animation: appliedPreview
                    ) {
                        Button(Localized.string("app.changeCursorFile")) {
                            controller.chooseOverride(for: assignment.role)
                        }
                    }
                } else {
                    EmptyPreviewGroup(
                        subtitle: assignment.sourceURL?.lastPathComponent ?? Localized.string("app.noCursorLoaded")
                    ) {
                        Button(Localized.string("app.changeCursorFile")) {
                            controller.chooseOverride(for: assignment.role)
                        }
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        if assignment.usesArrowFallback {
                            Label(Localized.string("app.arrowFallbackDescription"), systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        DetailItem(title: Localized.string("app.role")) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(assignment.role.displayName)
                            }
                        }
                        DetailItem(title: Localized.string("app.mousecape")) {
                            Text(assignment.role.mousecapeMappingDescription)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        DetailItem(title: Localized.string("app.currentSource")) {
                            Text(assignment.sourceURL?.path ?? Localized.string("app.automaticallyMatchedInsideSelectedFolder"))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        if assignment.usesArrowFallback {
                            DetailItem(title: Localized.string("app.status")) {
                                Text(Localized.string("app.automaticMatchFailedArrowFallbackShort"))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    EmptyView()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct SettingsHeader: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localized.string("app.cursorFolder"))
                            .font(.headline)
                        Text(controller.selectedFolderURL?.path ?? Localized.string("app.noFolderSelected"))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button(Localized.string("app.chooseFolder")) {
                        controller.chooseThemeFolder()
                    }
                }

            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PreviewGroup<TrailingAction: View>: View {
    let subtitle: String
    let animation: CursorAnimation
    let trailingAction: TrailingAction
    @ObservedObject private var localization = LocalizationController.shared

    init(
        subtitle: String,
        animation: CursorAnimation,
        @ViewBuilder trailingAction: () -> TrailingAction = { EmptyView() }
    ) {
        self.subtitle = subtitle
        self.animation = animation
        self.trailingAction = trailingAction()
    }

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    trailingAction
                }

                CursorPreviewView(animation: animation)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        } label: {
            EmptyView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetailItem<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.weight(.semibold))
            content
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
    }
}

struct EmptyPreviewGroup<TrailingAction: View>: View {
    let subtitle: String
    let trailingAction: TrailingAction
    @ObservedObject private var localization = LocalizationController.shared

    init(
        subtitle: String,
        @ViewBuilder trailingAction: () -> TrailingAction = { EmptyView() }
    ) {
        self.subtitle = subtitle
        self.trailingAction = trailingAction()
    }

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    trailingAction
                }

                VStack(spacing: 10) {
                    Image(systemName: "cursorarrow")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text(Localized.string("app.cursorWillAppearHere"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 220)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        } label: {
            EmptyView()
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
