import ArgumentParser
import Foundation

enum SortField: String, ExpressibleByArgument, CaseIterable {
    case memory
    case pid
    case name
}

enum CategoryFilter: String, ExpressibleByArgument, CaseIterable {
    case safe
    case caution
    case critical
    case all
}

struct TopCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "top",
        abstract: "Show top memory-consuming processes"
    )

    @Option(name: .shortAndLong, help: "Number of processes to show")
    var number: Int = 20

    @Flag(name: .shortAndLong, help: "Show all processes")
    var all: Bool = false

    @Option(name: .long, help: "Sort by: memory, pid, or name")
    var sort: SortField = .memory

    @Option(name: .long, help: "Filter by category: safe, caution, critical, or all")
    var category: CategoryFilter = .all

    func run() throws {
        var processes = ProcessService.listAll()
        processes = CategoryService.categorizeAll(processes)

        // Filter by category
        if category != .all {
            let targetCategory: SafetyCategory = {
                switch category {
                case .safe: return .safe
                case .caution: return .caution
                case .critical: return .critical
                case .all: return .safe // unreachable
                }
            }()
            processes = processes.filter { $0.category == targetCategory }
        }

        // Sort
        switch sort {
        case .memory:
            processes.sort { $0.memoryBytes > $1.memoryBytes }
        case .pid:
            processes.sort { $0.pid < $1.pid }
        case .name:
            processes.sort { $0.name.lowercased() < $1.name.lowercased() }
        }

        // Limit
        if !all {
            processes = Array(processes.prefix(number))
        }

        if processes.isEmpty {
            print(ANSIStyle.styled("No processes found matching the criteria.", .yellow))
            return
        }

        let title = "Top \(processes.count) Processes by Memory Usage"
        print(ANSIStyle.styled(title, .boldWhite))
        print()
        TableFormatter.printProcessTable(processes)
        print()

        // Summary
        let totalMemory = processes.reduce(UInt64(0)) { $0 + $1.memoryBytes }
        print(ANSIStyle.styled("Total memory (shown): ", .dim) + ANSIStyle.styled(ByteFormatter.format(totalMemory), .boldCyan))
    }
}
