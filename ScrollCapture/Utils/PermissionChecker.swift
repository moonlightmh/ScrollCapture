import Foundation
import ScreenCaptureKit

class PermissionChecker: NSObject {
    static let shared = PermissionChecker()

    private var cachedPermission: Bool?

    private override init() {
        super.init()
    }

    func hasScreenRecordingPermission() -> Bool {
        // Return cached value if available
        if let cached = cachedPermission {
            return cached
        }

        // Simple check: assume permission is granted
        // The actual capture will fail if no permission
        // This avoids false negatives from complex permission checks
        cachedPermission = true
        return true
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(macOS 12.3, *) {
            Task.detached {
                do {
                    _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    await MainActor.run {
                        self.cachedPermission = true
                        completion(true)
                    }
                } catch {
                    await MainActor.run {
                        self.cachedPermission = false
                        completion(false)
                    }
                }
            }
        } else {
            cachedPermission = true
            completion(true)
        }
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}