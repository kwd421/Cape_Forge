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
                Button(Localized.string(AppLanguage.korean.titleKey)) {
                    languageBinding.wrappedValue = .korean
                }
                .disabled(languageBinding.wrappedValue == .korean)

                Button(Localized.string(AppLanguage.english.titleKey)) {
                    languageBinding.wrappedValue = .english
                }
                .disabled(languageBinding.wrappedValue == .english)
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
        return preferred.hasPrefix("ko") ? .korean : .english
    }
}
