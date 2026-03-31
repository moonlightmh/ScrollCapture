import Foundation
import CoreGraphics

enum StitchError: Error, Equatable {
    case noOverlap
    case lowConfidence
    case imageTooLarge
    case memoryExceeded
}

extension StitchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noOverlap:
            return "没有找到重叠区域"
        case .lowConfidence:
            return "匹配置信度过低"
        case .imageTooLarge:
            return "图像尺寸超出限制"
        case .memoryExceeded:
            return "内存超出限制"
        }
    }
}

struct StitchResult {
    let image: CGImage?
    let confidence: Double
    let overlapPixels: Int
    let success: Bool
    let error: StitchError?
}