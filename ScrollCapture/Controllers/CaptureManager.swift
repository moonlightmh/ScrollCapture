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
            if #available(macOS 14.0, *) {
                if let image = await captureRegionModern(rect) {
                    await MainActor.run {
                        session.addScreenshot(image)
                        AppState.shared.screenshotCount += 1
                        self.stitchNewImage(image)
                    }
                }
            } else if #available(macOS 12.3, *) {
                if let image = await captureRegionAsyncLegacy(rect) {
                    await MainActor.run {
                        session.addScreenshot(image)
                        AppState.shared.screenshotCount += 1
                        self.stitchNewImage(image)
                    }
                }
            } else {
                // macOS 12.0-12.2 fallback
                if let image = captureRegionLegacy(rect) {
                    session.addScreenshot(image)
                    AppState.shared.screenshotCount += 1
                    self.stitchNewImage(image)
                }
            }
        }
    }

    @available(macOS 14.0, *)
    private func captureRegionModern(_ rect: CGRect) async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return nil }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = Int(rect.width)
            config.height = Int(rect.height)
            config.sourceRect = CGRect(
                x: rect.origin.x,
                y: display.frame.height - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )

            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return image
        } catch {
            print("Capture error: \(error)")
            return nil
        }
    }

    @available(macOS 12.3, *)
    private func captureRegionAsyncLegacy(_ rect: CGRect) async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return nil }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = Int(rect.width)
            config.height = Int(rect.height)
            config.sourceRect = CGRect(
                x: rect.origin.x,
                y: display.frame.height - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )

            // Use SCStream for older macOS versions
            let stream = SCStream(filter: filter, configuration: config, delegate: nil)
            // This is a simplified approach - actual implementation would need a proper delegate
            return nil // Placeholder - will need proper stream handling
        } catch {
            print("Capture error: \(error)")
            return nil
        }
    }

    private func captureRegionLegacy(_ rect: CGRect) -> CGImage? {
        // Use CGWindowListCreateImage for macOS 12.0-12.2
        let image = CGWindowListCreateImage(
            CGRectNull,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.boundsIgnoreFraming, .nominalResolution]
        )

        if let fullImage = image {
            return fullImage.cropping(to: rect)
        }
        return nil
    }

    private func stitchNewImage(_ image: CGImage) {
        guard let session = AppState.shared.currentSession else { return }

        if session.stitchedResult == nil {
            session.updateStitchedResult(image)
            return
        }

        let result = StitchEngine.shared.stitch(
            baseImage: session.stitchedResult!,
            newImage: image
        )

        if result.success, let newResult = result.image {
            session.updateStitchedResult(newResult)
            session.recordOverlap(result.overlapPixels)
        } else {
            AppState.shared.statusMessage = "拼接警告: \(result.error?.localizedDescription ?? "未知错误")"
        }
    }
}