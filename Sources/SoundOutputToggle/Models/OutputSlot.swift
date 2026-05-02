enum OutputSlot {
    case primary
    case secondary
    case unknown

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
