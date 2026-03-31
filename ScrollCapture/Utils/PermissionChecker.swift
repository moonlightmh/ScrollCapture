import Foundation
import ScreenCaptureKit

class PermissionChecker {
    static let shared = PermissionChecker()

    private init() {}

    func hasScreenRecordingPermission() -> Bool {
        // On macOS 12.0+, we can check by trying to capture
        do {
            let content = try SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return content.windows.count >= 0  // If we get here, permission granted
        } catch {
            return false
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        // Screen recording permission must be granted in System Settings
        // We cannot programmatically request it, but we can prompt user
        completion(hasScreenRecordingPermission())
    }

    func openPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}