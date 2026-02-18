import Foundation

enum SafetyCategory: String, CaseIterable, Comparable {
    case safe
    case caution
    case critical

    var label: String {
        switch self {
        case .safe: return "Safe"
        case .caution: return "Caution"
        case .critical: return "Critical"
        }
    }

    var coloredLabel: String {
        switch self {
        case .safe: return ANSIStyle.styled("Safe", .green)
        case .caution: return ANSIStyle.styled("Caution", .yellow)
        case .critical: return ANSIStyle.styled("Critical", .red)
        }
    }

    var description: String {
        switch self {
        case .safe: return "User application, safe to close"
        case .caution: return "Apple user-space service, close with care"
        case .critical: return "System-critical process, do not close"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .safe: return 0
        case .caution: return 1
        case .critical: return 2
        }
    }

    static func < (lhs: SafetyCategory, rhs: SafetyCategory) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
