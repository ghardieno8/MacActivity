import ArgumentParser
import Foundation

struct StatsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stats",
        abstract: "Show system memory overview"
    )

    func run() throws {
        guard let stats = MemoryService.getStats() else {
            print(ANSIStyle.styled("Error: Could not retrieve memory statistics.", .red))
            throw ExitCode.failure
        }

        print(ANSIStyle.styled("System Memory Overview", .boldWhite))
        print()

        // Memory pressure bar
        print(ANSIStyle.styled("  Memory Pressure: ", .bold) + stats.pressureBar)
        print(ANSIStyle.styled("  Status:          ", .bold) + stats.pressureLevel)
        print()

        // Breakdown
        let labelWidth = 18
        func row(_ label: String, _ value: String, color: ANSIColor = .white) {
            let paddedLabel = label.padding(toLength: labelWidth, withPad: " ", startingAt: 0)
            print("  " + ANSIStyle.styled(paddedLabel, .dim) + ANSIStyle.styled(value, color))
        }

        row("Total Memory:", stats.totalFormatted, color: .boldWhite)
        row("Used Memory:", stats.usedFormatted, color: .yellow)
        row("Free Memory:", stats.freeFormatted, color: .green)
        print()
        row("Active:", stats.activeFormatted, color: .cyan)
        row("Inactive:", stats.inactiveFormatted, color: .blue)
        row("Wired:", stats.wiredFormatted, color: .magenta)
        row("Compressed:", stats.compressedFormatted, color: .yellow)
        print()
        row("App Memory:", stats.appMemoryFormatted, color: .boldCyan)
        print()

        // Category breakdown from processes
        let processes = CategoryService.categorizeAll(ProcessService.listAll())
        let safeProcesses = processes.filter { $0.category == .safe }
        let cautionProcesses = processes.filter { $0.category == .caution }
        let criticalProcesses = processes.filter { $0.category == .critical }

        let safeMemory = safeProcesses.reduce(UInt64(0)) { $0 + $1.memoryBytes }
        let cautionMemory = cautionProcesses.reduce(UInt64(0)) { $0 + $1.memoryBytes }
        let criticalMemory = criticalProcesses.reduce(UInt64(0)) { $0 + $1.memoryBytes }

        print(ANSIStyle.styled("  Process Categories:", .bold))
        print("  " + ANSIStyle.styled("Safe:     ", .green) + "\(safeProcesses.count) processes, \(ByteFormatter.format(safeMemory))")
        print("  " + ANSIStyle.styled("Caution:  ", .yellow) + "\(cautionProcesses.count) processes, \(ByteFormatter.format(cautionMemory))")
        print("  " + ANSIStyle.styled("Critical: ", .red) + "\(criticalProcesses.count) processes, \(ByteFormatter.format(criticalMemory))")
        print()
    }
}
