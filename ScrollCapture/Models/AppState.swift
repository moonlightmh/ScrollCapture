import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var captureState: CaptureState = .idle
    @Published var screenshotCount: Int = 0
    @Published var statusMessage: String = ""

    var currentSession: CaptureSession?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadPersistedSettings()
    }

    // Persisted settings
    @AppStorage(Constants.StorageKeys.exportFormat) var exportFormat: String = Constants.Defaults.exportFormat
    @AppStorage(Constants.StorageKeys.jpgQuality) var jpgQuality: Double = Constants.Defaults.jpgQuality
    @AppStorage(Constants.StorageKeys.lastExportPath) var lastExportPath: String = ""
    @AppStorage(Constants.StorageKeys.learnedOverlap) var learnedOverlap: Int = Constants.Defaults.templateHeight
    @AppStorage(Constants.StorageKeys.templateHeight) var templateHeight: Int = Constants.Defaults.templateHeight
    @AppStorage(Constants.StorageKeys.matchThreshold) var matchThreshold: Double = Constants.Defaults.matchThreshold
    @AppStorage(Constants.StorageKeys.maxResultHeight) var maxResultHeight: Int = Constants.Defaults.maxResultHeight

    func startNewSession() {
        currentSession = CaptureSession()
        captureState = .selectingArea
        screenshotCount = 0
        statusMessage = "选择截图区域"
    }

    func endSession() {
        if let session = currentSession {
            session.clear()
        }
        currentSession = nil
        captureState = .idle
        screenshotCount = 0
        statusMessage = ""
    }

    func cancelSession() {
        endSession()
        statusMessage = "截图已取消"
    }

    private func loadPersistedSettings() {
        // Settings are auto-loaded via @AppStorage
    }
}