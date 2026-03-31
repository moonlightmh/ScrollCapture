import XCTest
@testable import ScrollCapture

final class CaptureSessionTests: XCTestCase {

    var session: CaptureSession!

    override func setUp() {
        session = CaptureSession()
    }

    override func tearDown() {
        session.clear()
    }

    func testSetSelectedRect() {
        let rect = CGRect(x: 100, y: 100, width: 500, height: 300)
        session.setSelectedRect(rect)

        XCTAssertEqual(session.selectedRect, rect)
    }

    func testRecordOverlap() {
        session.recordOverlap(100)
        session.recordOverlap(120)
        session.recordOverlap(80)

        XCTAssertEqual(session.overlapHistory.count, 3)
        XCTAssertEqual(session.averageOverlap, 100)
    }

    func testClear() {
        session.setSelectedRect(CGRect(x: 0, y: 0, width: 100, height: 100))
        session.recordOverlap(50)

        session.clear()

        XCTAssertNil(session.selectedRect)
        XCTAssertTrue(session.overlapHistory.isEmpty)
    }
}