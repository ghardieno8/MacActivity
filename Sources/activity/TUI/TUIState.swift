import Foundation

enum TUISortField: CaseIterable {
    case memory, pid, name

    var label: String {
        switch self {
        case .memory: return "Memory ↓"
        case .pid: return "PID ↑"
        case .name: return "Name ↑"
        }
    }

    func next() -> TUISortField {
        let all = TUISortField.allCases
        let idx = all.firstIndex(of: self)!
        return all[(idx + 1) % all.count]
    }
}

enum TUIFilterCategory: CaseIterable {
    case all, safe, caution, critical

    var label: String {
        switch self {
        case .all: return "All"
        case .safe: return "Safe"
        case .caution: return "Caution"
        case .critical: return "Critical"
        }
    }

    func next() -> TUIFilterCategory {
        let all = TUIFilterCategory.allCases
        let idx = all.firstIndex(of: self)!
        return all[(idx + 1) % all.count]
    }

    func matches(_ category: SafetyCategory) -> Bool {
        switch self {
        case .all: return true
        case .safe: return category == .safe
        case .caution: return category == .caution
        case .critical: return category == .critical
        }
    }
}

enum ConfirmAction {
    case killSingle(ProcessEntry)
    case cleanupBatch([ProcessEntry], UInt64) // processes, total bytes
}

enum TUIMode: Equatable {
    case normal
    case search
    case confirm
}

final class TUIState {
    // Data
    var allProcesses: [ProcessEntry] = []
    var memoryStats: MemoryStats?

    // View controls
    var sort: TUISortField = .memory
    var filter: TUIFilterCategory = .all
    var searchQuery: String = ""
    var mode: TUIMode = .normal

    // Selection / scroll
    var selectedIndex: Int = 0
    var scrollOffset: Int = 0

    // Confirmation
    var pendingAction: ConfirmAction?

    // Terminal
    var termWidth: Int = 80
    var termHeight: Int = 24

    /// The filtered + sorted + searched list for display.
    var displayProcesses: [ProcessEntry] {
        var list = allProcesses.filter { filter.matches($0.category) }

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) }
        }

        switch sort {
        case .memory: list.sort { $0.memoryBytes > $1.memoryBytes }
        case .pid: list.sort { $0.pid < $1.pid }
        case .name: list.sort { $0.name.lowercased() < $1.name.lowercased() }
        }

        return list
    }

    /// Number of rows available for the process table (total height minus header/footer).
    var tableRows: Int {
        max(1, termHeight - 5) // 2 header lines + separator + 1 status bar + 1 help bar
    }

    func clampSelection() {
        let count = displayProcesses.count
        if count == 0 {
            selectedIndex = 0
            scrollOffset = 0
            return
        }
        selectedIndex = max(0, min(selectedIndex, count - 1))
        // Ensure selected row is visible
        if selectedIndex < scrollOffset {
            scrollOffset = selectedIndex
        }
        if selectedIndex >= scrollOffset + tableRows {
            scrollOffset = selectedIndex - tableRows + 1
        }
    }

    func refreshData() {
        var processes = ProcessService.listAll()
        processes = CategoryService.categorizeAll(processes)
        allProcesses = processes
        memoryStats = MemoryService.getStats()
        clampSelection()
    }
}
