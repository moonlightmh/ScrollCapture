import Cocoa
import SwiftUI

class SelectionOverlayController: NSObject {
    static let shared = SelectionOverlayController()

    private var overlayWindow: NSPanel?
    private var isSelecting = false
    private var startPoint: CGPoint = .zero
    private var eventMonitor: Any?

    private override init() {
        super.init()
    }

    func showOverlay() {
        guard overlayWindow == nil else {
            return
        }

        // Create fullscreen transparent window using NSPanel
        let screenFrame = NSScreen.main?.frame ?? .zero

        overlayWindow = NSPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Important settings for mouse events
        overlayWindow?.level = .popUpMenu
        overlayWindow?.backgroundColor = NSColor.black.withAlphaComponent(0.001) // Almost transparent but catches events
        overlayWindow?.ignoresMouseEvents = false
        overlayWindow?.acceptsMouseMovedEvents = true
        overlayWindow?.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .transient]
        overlayWindow?.becomesKeyOnlyIfNeeded = false
        overlayWindow?.hidesOnDeactivate = false
        overlayWindow?.isFloatingPanel = true

        // Create SwiftUI view
        let contentView = NSHostingView(rootView: SelectionOverlayView(
            onStartSelection: { [weak self] point in
                self?.startSelection(at: point)
            },
            onUpdateSelection: { [weak self] rect in
                self?.updateSelection(rect)
            },
            onEndSelection: { [weak self] rect in
                self?.endSelection(rect)
            },
            onCancel: { [weak self] in
                self?.cancelSelection()
            }
        ))

        overlayWindow?.contentView = contentView
        overlayWindow?.makeKeyAndOrderFront(nil)

        // Add Esc key monitor
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc key
                self?.cancelSelection()
                return nil
            }
            return event
        }
    }

    func hideOverlay() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        overlayWindow?.close()
        overlayWindow = nil
    }

    private func startSelection(at point: CGPoint) {
        isSelecting = true
        startPoint = point
    }

    private func updateSelection(_ rect: CGRect) {
        // Update view with selection rect
    }

    private func endSelection(_ rect: CGRect) {
        isSelecting = false

        // Validate rect before hiding overlay
        let validRect = validateRect(rect)

        if validRect.width > 10 && validRect.height > 10 {
            // Hide overlay first
            hideOverlay()
            // Then call confirmSelection
            CaptureManager.shared.confirmSelection(rect: validRect)
        } else {
            hideOverlay()
            AppState.shared.statusMessage = "请选择有效的截图区域"
            AppState.shared.captureState = .idle
        }
    }

    private func cancelSelection() {
        isSelecting = false
        hideOverlay()
        AppState.shared.cancelSession()
    }

    private func validateRect(_ rect: CGRect) -> CGRect {
        let screenFrame = NSScreen.main?.frame ?? .zero
        return rect.intersection(screenFrame)
    }
}