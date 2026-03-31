import XCTest
@testable import ScrollCapture

final class StitchResultTests: XCTestCase {

    func testSuccessResult() {
        let result = StitchResult(
            confidence: 0.95,
            overlapPixels: 100,
            success: true,
            error: nil
        )
        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(result.confidence, 0.85)
        XCTAssertEqual(result.overlapPixels, 100)
        XCTAssertNil(result.error)
    }

    func testFailureResult() {
        let result = StitchResult(
            confidence: 0.6,
            overlapPixels: 0,
            success: false,
            error: .lowConfidence
        )
        XCTAssertFalse(result.success)
        XCTAssertLessThan(result.confidence, 0.85)
        XCTAssertEqual(result.error, .lowConfidence)
    }

    func testNoOverlapError() {
        let error = StitchError.noOverlap
        XCTAssertEqual(error.localizedDescription, "没有找到重叠区域")
    }

    func testImageTooLargeError() {
        let error = StitchError.imageTooLarge
        XCTAssertEqual(error.localizedDescription, "图像尺寸超出限制")
    }
}