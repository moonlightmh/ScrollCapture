import XCTest
@testable import ScrollCapture

final class CaptureStateTests: XCTestCase {

    func testInitialStateIsIdle() {
        let state = CaptureState.idle
        XCTAssertFalse(state.isCapturing)
        XCTAssertFalse(state.isSelecting)
    }

    func testCapturingStateIsCapturing() {
        let state = CaptureState.capturing
        XCTAssertTrue(state.isCapturing)
        XCTAssertFalse(state.isSelecting)
    }

    func testSelectingStateIsSelecting() {
        let state = CaptureState.selectingArea
        XCTAssertTrue(state.isSelecting)
        XCTAssertFalse(state.isCapturing)
    }

    func testErrorStateHasMessage() {
        let state = CaptureState.error("Test error")
        XCTAssertEqual(state.errorMessage, "Test error")
        XCTAssertTrue(state.isError)
    }
}