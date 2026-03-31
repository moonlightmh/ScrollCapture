import Foundation
import AppKit
import UniformTypeIdentifiers

class ExportManager {
    static let shared = ExportManager()

    private init() {}

    func export() {
        guard let session = AppState.shared.currentSession else {
            AppState.shared.endSession()
            return
        }

        guard let result = session.stitchedResult else {
            ToastController.shared.showToast(message: "没有可导出的图片")
            AppState.shared.endSession()
            return
        }

        showSavePanel(for: result)
    }

    func exportImage(_ image: CGImage, to url: URL, format: String, quality: Double) -> Bool {
        let data: Data?

        if format == "JPG" {
            data = imageToJPEG(image, quality: quality)
        } else {
            data = imageToPNG(image)
        }

        guard let imageData = data else {
            return false
        }

        do {
            try imageData.write(to: url)
            return true
        } catch {
            print("Export error: \(error)")
            return false
        }
    }

    private func showSavePanel(for image: CGImage) {
        let savePanel = NSSavePanel()
        savePanel.title = "保存长图"
        savePanel.nameFieldStringValue = "长截图_\(timestamp())"

        // Set allowed types based on preference
        let preferredFormat = AppState.shared.exportFormat
        if preferredFormat == "JPG" {
            savePanel.allowedContentTypes = [.jpeg]
            savePanel.nameFieldStringValue += ".jpg"
        } else {
            savePanel.allowedContentTypes = [.png]
            savePanel.nameFieldStringValue += ".png"
        }

        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false

        // Add format selector
        let formatPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        formatPopup.addItems(withTitles: ["PNG", "JPG"])
        formatPopup.selectItem(at: preferredFormat == "JPG" ? 1 : 0)

        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
        let label = NSTextField(labelWithString: "格式:")
        label.frame = NSRect(x: 0, y: 5, width: 40, height: 20)
        formatPopup.frame = NSRect(x: 45, y: 3, width: 80, height: 24)
        accessoryView.addSubview(label)
        accessoryView.addSubview(formatPopup)
        savePanel.accessoryView = accessoryView

        // Set default directory
        let defaultPath = AppState.shared.lastExportPath
        if !defaultPath.isEmpty {
            savePanel.directoryURL = URL(fileURLWithPath: defaultPath)
        }

        savePanel.begin { response in
            if response == .OK {
                let url = savePanel.url!
                let selectedFormat = formatPopup.titleOfSelectedItem ?? "PNG"

                // Update extension if needed
                var finalURL = url
                if selectedFormat == "JPG" && !url.pathExtension.lowercased().hasPrefix("jp") {
                    finalURL = url.deletingPathExtension().appendingPathExtension("jpg")
                } else if selectedFormat == "PNG" && url.pathExtension.lowercased() != "png" {
                    finalURL = url.deletingPathExtension().appendingPathExtension("png")
                }

                let quality = AppState.shared.jpgQuality

                if self.exportImage(image, to: finalURL, format: selectedFormat, quality: quality) {
                    AppState.shared.lastExportPath = finalURL.deletingLastPathComponent().path

                    ToastController.shared.showToast(
                        message: "已保存到 \(finalURL.lastPathComponent)",
                        action: {
                            NSWorkspace.shared.activateFileViewerSelecting([finalURL])
                        }
                    )

                    AppState.shared.endSession()
                } else {
                    ToastController.shared.showToast(message: "导出失败，请重试")
                    AppState.shared.captureState = .capturing
                }
            } else {
                // User cancelled
                AppState.shared.captureState = .capturing
            }
        }
    }

    private func imageToPNG(_ image: CGImage) -> Data? {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        return mutableData as Data
    }

    private func imageToJPEG(_ image: CGImage, quality: Double) -> Data? {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let options: [NSString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        CGImageDestinationFinalize(destination)

        return mutableData as Data
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}