import Foundation

enum CaptureState: Equatable {
    case idle
    case selectingArea
    case capturing
    case exporting
    case error(String)

    var isCapturing: Bool {
        self == .capturing
    }

    var isSelecting: Bool {
        self == .selectingArea
    }

    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }

    static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.selectingArea, .selectingArea):
            return true
        case (.capturing, .capturing):
            return true
        case (.exporting, .exporting):
            return true
        case (.error(let lMsg), .error(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}