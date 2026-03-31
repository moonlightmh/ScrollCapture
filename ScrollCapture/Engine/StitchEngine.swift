import Foundation
import CoreGraphics

class StitchEngine {
    static let shared = StitchEngine()

    private var bridge: StitchEngineBridge
    private var _overlapEstimate: Int = Constants.Defaults.templateHeight
    private var _learnedOverlap: Int?

    var overlapEstimate: Int {
        get { _overlapEstimate }
        set { _overlapEstimate = newValue }
    }

    var learnedOverlap: Int? {
        get { _learnedOverlap }
    }

    var maxResultHeight: Int {
        get { AppState.shared.maxResultHeight }
    }

    private init() {
        bridge = StitchEngineBridge(
            templateHeight: Int32(Constants.Defaults.templateHeight),
            matchThreshold: Constants.Defaults.matchThreshold,
            maxResultHeight: Int32(Constants.Defaults.maxResultHeight)
        )
    }

    func stitch(baseImage: CGImage?, newImage: CGImage) -> StitchResult {
        guard let baseImage = baseImage else {
            // First image - just return it as the base
            return StitchResult(
                image: newImage,
                confidence: 1.0,
                overlapPixels: 0,
                success: true,
                error: nil
            )
        }

        let bridgeResult = bridge.stitchBaseImage(baseImage, withNewImage: newImage)

        let error: StitchError? = {
            switch bridgeResult.errorCode {
            case 1: return .noOverlap
            case 2: return .lowConfidence
            case 3: return .imageTooLarge
            case 4: return .memoryExceeded
            default: return nil
            }
        }()

        return StitchResult(
            image: bridgeResult.imageRef,
            confidence: bridgeResult.confidence,
            overlapPixels: Int(bridgeResult.overlapPixels),
            success: bridgeResult.success,
            error: error
        )
    }

    func reset() {
        bridge.reset()
        _learnedOverlap = nil
    }

    // MARK: - Rebuild Support

    /// Stitch all images from scratch (for undo/rebuild functionality)
    func stitchAll(images: [CGImage]) -> CGImage? {
        guard !images.isEmpty else { return nil }

        var currentResult: CGImage? = images.first

        for i in 1..<images.count {
            let result = stitch(baseImage: currentResult, newImage: images[i])
            if result.success, let newResult = result.image {
                currentResult = newResult
            } else {
                // If stitch fails, continue with current result
                // but log the issue
                print("Stitch failed at image \(i): \(result.error?.localizedDescription ?? "unknown error")")
            }
        }

        return currentResult
    }
}