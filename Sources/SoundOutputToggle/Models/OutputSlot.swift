import Foundation

enum OutputSlot: String {
    case primary = "A"
    case secondary = "B"
    case unknown = "?"

    var displayName: String {
        switch self {
        case .primary:
            return "Output A"
        case .secondary:
            return "Output B"
        case .unknown:
            return "Unknown"
        }
    }
}
