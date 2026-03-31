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
}