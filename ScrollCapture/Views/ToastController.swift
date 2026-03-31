import Cocoa
import SwiftUI

class ToastController: NSObject {
    static let shared = ToastController()

    private var toastWindow: NSWindow?
    private var hideTimer: Timer?

    private override init() {
        super.init()
    }

    func showToast(message: String, duration: TimeInterval = Constants.UI.toastDuration, action: (() -> Void)? = nil) {
        // Remove existing toast
        hideToast()

        // Create toast window
        let toastView = ToastView(message: message, action: action)
        let hostingView = NSHostingView(rootView: toastView)

        // Calculate size
        let size = hostingView.fittingSize
        let toastRect = NSRect(x: 0, y: 0, width: size.width + 20, height: size.height + 10)

        toastWindow = NSWindow(
            contentRect: toastRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        toastWindow?.level = .floating
        toastWindow?.backgroundColor = .clear
        if #available(macOS 13.0, *) {
            toastWindow?.collectionBehavior = [.canJoinAllApplications]
        } else {
            toastWindow?.collectionBehavior = []
        }

        // Position near menu bar
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let menuBarHeight = screenFrame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
            let x = (screenFrame.width - toastRect.width) / 2
            let y = screenFrame.height - menuBarHeight - toastRect.height - 10
            toastWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        toastWindow?.contentView = hostingView
        toastWindow?.makeKeyAndOrderFront(nil)

        // Auto-hide timer
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hideToast()
        }
    }

    func hideToast() {
        hideTimer?.invalidate()
        hideTimer = nil
        toastWindow?.close()
        toastWindow = nil
    }
}