import Cocoa
import SwiftUI

class PreviewWindowController {
    static let shared = PreviewWindowController()

    private var previewWindow: NSWindow?
    private(set) var isVisible: Bool = false

    private init() {}

    func show() {
        DispatchQueue.main.async {
            self.showOnMainThread()
        }
    }

    private func showOnMainThread() {
        if previewWindow != nil {
            previewWindow?.makeKeyAndOrderFront(nil)
            isVisible = true
            return
        }

        // Create preview window
        let previewRect = NSRect(x: 0, y: 0, width: 240, height: 400)

        previewWindow = NSWindow(
            contentRect: previewRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        guard let window = previewWindow else { return }

        window.level = .floating
        window.backgroundColor = NSColor.black.withAlphaComponent(0.75)
        window.isOpaque = false
        window.hasShadow = true
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        window.ignoresMouseEvents = false

        // Position at right side of screen, below control panel
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = screenFrame.width - previewRect.width - 20
            let y = screenFrame.height - previewRect.height - 150
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Create SwiftUI preview view
        let contentView = PreviewView()
        let hostingView = NSHostingView(rootView: contentView)

        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        isVisible = true
    }

    func hide() {
        previewWindow?.orderOut(nil)
        isVisible = false
    }

    func close() {
        previewWindow?.close()
        previewWindow = nil
        isVisible = false
    }

    func updatePreview(image: CGImage) {
        DispatchQueue.main.async {
            AppState.shared.previewImage = image
        }
    }
}

// MARK: - SwiftUI Preview View

struct PreviewView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("预览")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if let image = appState.previewImage {
                    Text("\(image.width)×\(image.height)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            // Preview Image
            if let cgImage = appState.previewImage {
                GeometryReader { geometry in
                    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            } else {
                // Placeholder
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))

                    Text("等待截图...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            }

            // Footer - height indicator
            if let image = appState.previewImage {
                Text("高度: \(image.height) px")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 8)
            }
        }
        .background(Color.black.opacity(0.75))
        .cornerRadius(12)
    }
}