import Foundation
import CoreGraphics

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
}