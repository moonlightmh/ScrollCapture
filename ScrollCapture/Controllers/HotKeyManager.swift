import Foundation
import Combine

class HotKeyManager {
    static let shared = HotKeyManager()

    private var isRegistered = false

    private init() {}

    func registerHotkeys() {
        // Will be implemented with KeyboardShortcuts library or Carbon API
        isRegistered = true
    }

    func unregisterHotkeys() {
        isRegistered = false
    }

    func triggerScreenshot() {
        guard isRegistered, AppState.shared.captureState == .capturing else { return }
        CaptureManager.shared.captureScreenshot()
    }

    func triggerEndExport() {
        guard isRegistered, AppState.shared.captureState == .capturing else { return }
        AppState.shared.captureState = .exporting
        ExportManager.shared.export()
    }
}