import Foundation
import CoreGraphics
import ImageIO

class CaptureSession {
    var selectedRect: CGRect?
    var screenshots: [CGImage] = []
    var stitchedResult: CGImage?
    var overlapHistory: [Int] = []
    var tempFiles: [URL] = []

    let sessionId: String

    init() {
        sessionId = UUID().uuidString
        TempFileManager.shared.createSessionDirectory(sessionId)
    }

    func setSelectedRect(_ rect: CGRect) {
        selectedRect = rect
    }

    func addScreenshot(_ image: CGImage) {
        screenshots.append(image)

        // If memory limit exceeded, save to temp file
        if screenshots.count > Constants.Temp.maxInMemoryScreenshots {
            let oldest = screenshots.removeFirst()
            if let url = TempFileManager.shared.saveToTemp(oldest, sessionId: sessionId) {
                tempFiles.append(url)
            }
        }
    }

    func updateStitchedResult(_ image: CGImage) {
        stitchedResult = image
    }

    func recordOverlap(_ overlap: Int) {
        overlapHistory.append(overlap)
    }

    func clear() {
        screenshots.removeAll()
        stitchedResult = nil
        overlapHistory.removeAll()
        TempFileManager.shared.clearSessionDirectory(sessionId)
        tempFiles.removeAll()
        selectedRect = nil
    }

    var averageOverlap: Int {
        if overlapHistory.isEmpty {
            return Constants.Defaults.templateHeight
        }
        return overlapHistory.reduce(0, +) / overlapHistory.count
    }

    // MARK: - Undo Support

    /// Remove the last screenshot and return it
    func removeLastScreenshot() -> CGImage? {
        guard !screenshots.isEmpty else { return nil }
        return screenshots.popLast()
    }

    /// Remove the last overlap record
    func removeLastOverlap() {
        guard !overlapHistory.isEmpty else { return }
        overlapHistory.popLast()
    }

    /// Get all screenshots including those saved to temp files
    func getAllScreenshots() -> [CGImage] {
        var allImages: [CGImage] = []

        // Load images from temp files first (oldest)
        for url in tempFiles {
            if let image = loadImageFromURL(url) {
                allImages.append(image)
            }
        }

        // Add in-memory screenshots (newest)
        allImages.append(contentsOf: screenshots)

        return allImages
    }

    private func loadImageFromURL(_ url: URL) -> CGImage? {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return image
    }
}