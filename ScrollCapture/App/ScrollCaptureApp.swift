import SwiftUI

@main
struct ScrollCaptureApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene - this is a menu bar only app
        Settings {
            EmptyView()
        }
    }
}