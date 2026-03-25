import SwiftUI

@main
struct MacMouseCursorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("MacMouseCursor", systemImage: "cursorarrow.motionlines") {
            ContentView(controller: appDelegate.controller)
        }
        .menuBarExtraStyle(.window)
    }
}
