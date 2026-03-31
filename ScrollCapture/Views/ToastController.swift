import Cocoa
import SwiftUI

class ToastController: NSObject {
    static let shared = ToastController()

    private var toastWindow: NSWindow?
    private var hideTimer: Timer?

    private override init() {
        super.init()
    }

    func showToast(message: String, duration: TimeInterval = 3.0, action: (() -> Void)? = nil) {
        // Remove existing toast
        hideToast()

        DispatchQueue.main.async {
            // Create toast window
            let toastView = ToastView(message: message, action: action)
            let hostingView = NSHostingView(rootView: toastView)

            // Fixed size for visibility
            let toastRect = NSRect(x: 0, y: 0, width: 400, height: 50)

            self.toastWindow = NSWindow(
                contentRect: toastRect,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            self.toastWindow?.level = .floating
            self.toastWindow?.backgroundColor = .clear
            self.toastWindow?.isOpaque = false
            self.toastWindow?.hasShadow = true
            self.toastWindow?.collectionBehavior = [.fullScreenAuxiliary]

            // Position at top center of screen
            if let screen = NSScreen.main {
                let screenFrame = screen.frame
                let x = (screenFrame.width - toastRect.width) / 2
                let y = screenFrame.height - toastRect.height - 50
                self.toastWindow?.setFrameOrigin(NSPoint(x: x, y: y))
            }

            self.toastWindow?.contentView = hostingView
            self.toastWindow?.makeKeyAndOrderFront(nil)

            // Auto-hide timer
            self.hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                self.hideToast()
            }
        }
    }

    func hideToast() {
        hideTimer?.invalidate()
        hideTimer = nil
        toastWindow?.close()
        toastWindow = nil
    }
}

// MARK: - Floating Control View

struct FloatingControlView: View {
    let onCapture: () -> Void
    let onEnd: () -> Void
    let onUndo: () -> Void
    let onCancel: () -> Void
    let onTogglePreview: () -> Void

    @ObservedObject var appState = AppState.shared

    var body: some View {
        HStack(spacing: 8) {
            // 截图计数
            HStack(spacing: 4) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(appState.screenshotCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(minWidth: 40)

            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))

            // 预览按钮
            Button(action: onTogglePreview) {
                Image(systemName: appState.showPreview ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(appState.showPreview ? .cyan : .white.opacity(0.5))
            }
            .buttonStyle(ControlButtonStyle())
            .help("预览窗口")

            // 撤销按钮
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14))
                    .foregroundColor(appState.screenshotCount > 0 ? .orange : .white.opacity(0.3))
            }
            .buttonStyle(ControlButtonStyle())
            .disabled(appState.screenshotCount == 0)
            .help("撤销上一张")

            // 截图按钮
            Button(action: onCapture) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .buttonStyle(CaptureButtonStyle())
            .help("截图 (或按空格键)")

            // 取消按钮
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            .buttonStyle(ControlButtonStyle())
            .help("取消")

            // 结束按钮
            Button(action: onEnd) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
            .buttonStyle(ControlButtonStyle())
            .help("结束并导出")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Button Styles

struct ControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                Circle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.2 : 0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CaptureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                Circle()
                    .fill(Color.blue.opacity(configuration.isPressed ? 0.6 : 0.4))
            )
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Floating Control Controller

class FloatingControlController {
    static let shared = FloatingControlController()

    private var controlWindow: NSWindow?
    private var keyMonitor: Any?
    private var isDragging = false
    private var dragStartPoint: CGPoint = .zero

    func show() {
        DispatchQueue.main.async {
            self.showOnMainThread()
        }
    }

    private func showOnMainThread() {
        if controlWindow != nil {
            controlWindow?.close()
            controlWindow = nil
        }

        // Show preview window if enabled
        if AppState.shared.showPreview {
            PreviewWindowController.shared.show()
        }

        let contentView = FloatingControlView(
            onCapture: { [weak self] in
                self?.capture()
            },
            onEnd: { [weak self] in
                self?.endCapture()
            },
            onUndo: { [weak self] in
                self?.undo()
            },
            onCancel: { [weak self] in
                self?.cancel()
            },
            onTogglePreview: { [weak self] in
                self?.togglePreview()
            }
        )

        let hostingView = NSHostingView(rootView: contentView)
        let controlRect = NSRect(x: 0, y: 0, width: 280, height: 60)

        controlWindow = NSWindow(
            contentRect: controlRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        guard let window = controlWindow else {
            return
        }

        window.level = .statusBar
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false  // SwiftUI view has its own shadow
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true

        // Position at right side of screen, near top
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = screenFrame.width - controlRect.width - 20
            let y = screenFrame.height - controlRect.height - 80
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        // Make window draggable
        addDragSupport()

        // Add global key monitor for space key
        setupKeyMonitor()
    }

    private func addDragSupport() {
        guard let window = controlWindow else { return }

        // Add local monitor for mouse events in the window
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { event in
            guard let window = self.controlWindow else { return event }

            switch event.type {
            case .leftMouseDown:
                let locationInWindow = event.locationInWindow
                // Check if click is in the content area (for dragging)
                if locationInWindow.y < window.frame.height {
                    self.isDragging = true
                    self.dragStartPoint = NSEvent.mouseLocation
                }
            case .leftMouseDragged:
                if self.isDragging {
                    let currentLocation = NSEvent.mouseLocation
                    let deltaX = currentLocation.x - self.dragStartPoint.x
                    let deltaY = currentLocation.y - self.dragStartPoint.y
                    let newOrigin = window.frame.origin
                    window.setFrameOrigin(NSPoint(x: newOrigin.x + deltaX, y: newOrigin.y + deltaY))
                    self.dragStartPoint = currentLocation
                }
            case .leftMouseUp:
                self.isDragging = false
            default:
                break
            }

            return event
        }
    }

    private func setupKeyMonitor() {
        if keyMonitor != nil {
            NSEvent.removeMonitor(keyMonitor!)
        }
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49 { // Space key
                self.capture()
            } else if event.keyCode == 53 { // Esc key
                self.cancel()
            }
        }
    }

    func hide() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        controlWindow?.close()
        controlWindow = nil
        PreviewWindowController.shared.close()
    }

    private func capture() {
        CaptureManager.shared.captureScreenshot()
    }

    private func endCapture() {
        hide()
        AppState.shared.captureState = .exporting
        ExportManager.shared.export()
    }

    private func undo() {
        guard let session = AppState.shared.currentSession else { return }
        guard session.screenshots.count > 0 || session.tempFiles.count > 0 else { return }

        // Remove last screenshot
        if let removed = session.removeLastScreenshot() {
            AppState.shared.screenshotCount -= 1
            session.removeLastOverlap()

            // Rebuild stitched result
            let allImages = session.getAllScreenshots()
            if allImages.isEmpty {
                session.stitchedResult = nil
                AppState.shared.previewImage = nil
            } else {
                let newResult = StitchEngine.shared.stitchAll(images: allImages)
                session.updateStitchedResult(newResult!)
                AppState.shared.previewImage = newResult
            }
        }
    }

    private func cancel() {
        hide()
        AppState.shared.cancelSession()
    }

    private func togglePreview() {
        AppState.shared.showPreview.toggle()

        if AppState.shared.showPreview {
            PreviewWindowController.shared.show()
            if let result = AppState.shared.currentSession?.stitchedResult {
                PreviewWindowController.shared.updatePreview(image: result)
            }
        } else {
            PreviewWindowController.shared.hide()
        }
    }
}