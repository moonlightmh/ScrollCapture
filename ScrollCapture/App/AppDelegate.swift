import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItemController: StatusItemController?
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Clean up any leftover temp files from previous sessions
        TempFileManager.shared.clearAllTemp()

        // Check permissions
        if !PermissionChecker.shared.hasScreenRecordingPermission() {
            // Will be prompted when user tries to capture
        }

        // Initialize controllers
        statusItemController = StatusItemController()
        hotKeyManager = HotKeyManager.shared

        // Setup keyboard shortcut for settings (Cmd+,)
        setupSettingsShortcut()
    }

    private func setupSettingsShortcut() {
        // Cmd+, is standard macOS shortcut for settings
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.keyCode == 44 { // comma key
                SettingsWindowController.shared.showWindow()
                return nil
            }
            return event
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up temp files on exit
        TempFileManager.shared.clearAllTemp()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}