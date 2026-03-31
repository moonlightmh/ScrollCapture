import Foundation
import ScreenCaptureKit

class PermissionChecker {
    static let shared = PermissionChecker()

    private init() {}

    func hasScreenRecordingPermission() -> Bool {
        if #available(macOS 12.3, *) {
            // Use a simple approach with a result holder
            final class ResultHolder {
                var granted = false
            }
            let holder = ResultHolder()
            let semaphore = DispatchSemaphore(value: 0)

            Task { @MainActor in
                do {
                    _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    holder.granted = true
                } catch {
                    holder.granted = false
                }
                semaphore.signal()
            }

            semaphore.wait()
            return holder.granted
        } else {
            return checkPermissionLegacy()
        }
    }

    private func checkPermissionLegacy() -> Bool {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) else {
            return false
        }
        return CFArrayGetCount(windowList) > 0
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(macOS 12.3, *) {
            Task { @MainActor in
                var granted = false
                do {
                    _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    granted = true
                } catch {
                    granted = false
                }
                completion(granted)
            }
        } else {
            completion(checkPermissionLegacy())
        }
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}