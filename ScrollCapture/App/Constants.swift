import Foundation

enum Constants {
    // Default values
    enum Defaults {
        static let templateHeight: Int = 100
        static let matchThreshold: Double = 0.85
        static let maxResultHeight: Int = 50000
        static let jpgQuality: Double = 0.9
        static let exportFormat: String = "PNG"
        static let blankRegionHeight: Int = 50
    }

    // UI
    enum UI {
        static let overlayAlpha: Double = 0.3
        static let selectionBorderWidth: Double = 2.0
        static let toastDuration: TimeInterval = 3.0
    }

    // Storage keys
    enum StorageKeys {
        static let hotkeyScreenshot = "hotkeyScreenshot"
        static let hotkeyEnd = "hotkeyEnd"
        static let exportFormat = "exportFormat"
        static let jpgQuality = "jpgQuality"
        static let lastExportPath = "lastExportPath"
        static let learnedOverlap = "learnedOverlap"
        static let templateHeight = "templateHeight"
        static let matchThreshold = "matchThreshold"
        static let maxResultHeight = "maxResultHeight"
    }

    // Temp files
    enum Temp {
        static let cacheDirectory = "ScrollCapture"
        static let tempSubdirectory = "temp"
        static let maxInMemoryScreenshots = 3
    }
}