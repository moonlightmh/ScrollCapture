import Foundation
import ScreenCaptureKit
import CoreGraphics

class CaptureManager {
    static let shared = CaptureManager()

    private init() {}

    func startSelection() {
        SelectionOverlayController.shared.showOverlay()
        AppState.shared.captureState = .selectingArea
    }

    func confirmSelection(rect: CGRect) {
        guard let session = AppState.shared.currentSession else { return }
        session.setSelectedRect(rect)
        AppState.shared.captureState = .capturing
        AppState.shared.statusMessage = "按 Cmd+Shift+S 截图"
        HotKeyManager.shared.registerHotkeys()
    }

    func captureScreenshot() {
        guard let session = AppState.shared.currentSession,
              let rect = session.selectedRect else { return }

        Task {
            if let image = await captureRegionAsync(rect) {
                await MainActor.run {
                    session.addScreenshot(image)
                    AppState.shared.screenshotCount += 1
                    self.stitchNewImage(image)
                }
            }
        }
    }

    func captureRegionAsync(_ rect: CGRect) async -> CGImage? {
        do {
            // Get shareable content
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

            // Create capture configuration
            let filter = SCContentFilter(desktopIndependentWindow: nil)
            let config = SCStreamConfiguration()
            config.width = Int(rect.width)
            config.height = Int(rect.height)
            config.sourceRect = rect

            // Capture
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return image
        } catch {
            print("Capture error: \(error)")
            return nil
        }
    }

    private func stitchNewImage(_ image: CGImage) {
        guard let session = AppState.shared.currentSession else { return }

        // If this is the first screenshot, use it as base
        if session.stitchedResult == nil {
            session.updateStitchedResult(image)
            return
        }

        // Otherwise, call StitchEngine
        let result = StitchEngine.shared.stitch(
            baseImage: session.stitchedResult!,
            newImage: image
        )

        if result.success, let newResult = result.image {
            session.updateStitchedResult(newResult)
            session.recordOverlap(result.overlapPixels)
        } else {
            // Handle error - use fallback
            AppState.shared.statusMessage = "拼接警告: \(result.error?.localizedDescription ?? "未知错误")"
        }
    }
}