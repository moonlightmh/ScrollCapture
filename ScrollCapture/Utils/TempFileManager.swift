import Foundation
import CoreGraphics
import UniformTypeIdentifiers

class TempFileManager {
    static let shared = TempFileManager()

    let cacheDirectory: URL

    private init() {
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(Constants.Temp.cacheDirectory)

        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    func createSessionDirectory(_ sessionId: String) {
        let sessionUrl = cacheDirectory
            .appendingPathComponent(Constants.Temp.tempSubdirectory)
            .appendingPathComponent(sessionId)

        if !FileManager.default.fileExists(atPath: sessionUrl.path) {
            try? FileManager.default.createDirectory(at: sessionUrl, withIntermediateDirectories: true)
        }
    }

    func saveToTemp(_ image: CGImage, sessionId: String) -> URL? {
        let sessionUrl = cacheDirectory
            .appendingPathComponent(Constants.Temp.tempSubdirectory)
            .appendingPathComponent(sessionId)

        let fileName = "\(UUID().uuidString).png"
        let fileUrl = sessionUrl.appendingPathComponent(fileName)

        guard let data = imageToPNGData(image) else { return nil }

        do {
            try data.write(to: fileUrl)
            return fileUrl
        } catch {
            return nil
        }
    }

    func loadFromTemp(_ url: URL) -> CGImage? {
        guard let data = try? Data(contentsOf: url),
              let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return image
    }

    func clearSessionDirectory(_ sessionId: String) {
        let sessionUrl = cacheDirectory
            .appendingPathComponent(Constants.Temp.tempSubdirectory)
            .appendingPathComponent(sessionId)

        if FileManager.default.fileExists(atPath: sessionUrl.path) {
            try? FileManager.default.removeItem(at: sessionUrl)
        }
    }

    func clearAllTemp() {
        let tempUrl = cacheDirectory.appendingPathComponent(Constants.Temp.tempSubdirectory)

        if FileManager.default.fileExists(atPath: tempUrl.path) {
            try? FileManager.default.removeItem(at: tempUrl)
        }
    }

    private func imageToPNGData(_ image: CGImage) -> Data? {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return mutableData as Data
    }
}