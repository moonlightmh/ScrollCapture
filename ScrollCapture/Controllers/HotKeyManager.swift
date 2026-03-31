import Foundation
import Cocoa
import Combine

class HotKeyManager {
    static let shared = HotKeyManager()

    private var eventMonitor: Any?
    private var isRegistered = false

    private init() {}

    func registerHotkeys() {
        guard !isRegistered else { return }

        // Use NSEvent global monitor for hotkeys
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Cmd+Shift+S (screenshot) or Cmd+Shift+E (end)
            let isCmd = event.modifierFlags.contains(.command)
            let isShift = event.modifierFlags.contains(.shift)

            if isCmd && isShift {
                if event.keyCode == 1 { // S key
                    self?.triggerScreenshot()
                } else if event.keyCode == 14 { // E key
                    self?.triggerEndExport()
                }
            }
        }

        isRegistered = true
        print("✅ 热键已注册: Cmd+Shift+S 截图, Cmd+Shift+E 结束")
    }

    func unregisterHotkeys() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isRegistered = false
    }

    func triggerScreenshot() {
        guard isRegistered, AppState.shared.captureState == .capturing else { return }
        CaptureManager.shared.captureScreenshot()
        ToastController.shared.showToast(message: "已截图 \(AppState.shared.screenshotCount) 张", duration: 1.5)
    }

    func triggerEndExport() {
        guard isRegistered, AppState.shared.captureState == .capturing else { return }
        AppState.shared.captureState = .exporting
        unregisterHotkeys()
        ExportManager.shared.export()
    }
}