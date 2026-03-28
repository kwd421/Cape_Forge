import SwiftUI

@main
struct CapeForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var localization = LocalizationController.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandMenu("Language") {
                ForEach(AppLanguage.allCases) { language in
                    Button(Localized.string(language.titleKey)) {
                        languageBinding.wrappedValue = language
                    }
                    .disabled(languageBinding.wrappedValue == language)
                }
            }
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { localization.selectedLanguage ?? inferredInitialLanguage },
            set: { newValue in
                localization.setLanguage(newValue)
                appDelegate.controller.relocalize()
            }
        )
    }

    private var inferredInitialLanguage: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        if preferred.hasPrefix("ko") {
            return .korean
        }
        if preferred.hasPrefix("ja") {
            return .japanese
        }
        if preferred.contains("hant") {
            return .traditionalChinese
        }
        if preferred.hasPrefix("zh") {
            return .simplifiedChinese
        }
        if preferred.hasPrefix("de") {
            return .german
        }
        if preferred.hasPrefix("fr") {
            return .french
        }
        if preferred.hasPrefix("es") {
            return .spanish
        }
        if preferred.hasPrefix("pt") {
            return .portugueseBrazil
        }
        if preferred.hasPrefix("it") {
            return .italian
        }
        if preferred.hasPrefix("ru") {
            return .russian
        }
        return .english
    }
}
