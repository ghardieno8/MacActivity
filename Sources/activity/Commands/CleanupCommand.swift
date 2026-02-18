import ArgumentParser
import Foundation

struct CleanupCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cleanup",
        abstract: "Interactive cleanup of safe-to-close processes"
    )

    @Option(name: .shortAndLong, help: "Minimum memory threshold in MB to include a process")
    var threshold: Int = 50

    @Flag(name: .long, help: "Show what would be killed without actually killing")
    var dryRun: Bool = false

    @Flag(name: .shortAndLong, help: "Skip confirmation prompts")
    var yes: Bool = false

    func run() throws {
        let thresholdBytes = UInt64(threshold) * 1024 * 1024

        var processes = ProcessService.listAll()
        processes = CategoryService.categorizeAll(processes)

        // Filter to safe processes above threshold, exclude self
        let candidates = processes
            .filter { $0.category == .safe && $0.memoryBytes >= thresholdBytes && !$0.isCurrentProcess }
            .sorted { $0.memoryBytes > $1.memoryBytes }

        if candidates.isEmpty {
            print(ANSIStyle.styled("No safe-to-close processes found above \(threshold) MB threshold.", .yellow))
            return
        }

        let totalReclaimable = candidates.reduce(UInt64(0)) { $0 + $1.memoryBytes }

        print(ANSIStyle.styled("Memory Cleanup", .boldWhite))
        print(ANSIStyle.styled("Showing safe-to-close processes using ≥ \(threshold) MB", .dim))
        print()

        TableFormatter.printNumberedProcessTable(candidates)
        print()

        print(ANSIStyle.styled("Potentially reclaimable: ", .dim) +
              ANSIStyle.styled(ByteFormatter.format(totalReclaimable), .boldCyan))
        print()

        if dryRun {
            print(ANSIStyle.styled("Dry run mode — no processes were terminated.", .yellow))
            return
        }

        // Interactive mode
        if !yes {
            print("Enter process numbers to kill (comma-separated), 'all' for all, or 'q' to quit:")
            print("> ", terminator: "")
            fflush(stdout)

            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
                print(ANSIStyle.styled("Cancelled.", .dim))
                return
            }

            if input.lowercased() == "q" || input.isEmpty {
                print(ANSIStyle.styled("Cancelled.", .dim))
                return
            }

            let selected: [ProcessEntry]
            if input.lowercased() == "all" {
                selected = candidates
            } else {
                let indices = input.split(separator: ",")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                    .map { $0 - 1 } // Convert to 0-indexed
                    .filter { $0 >= 0 && $0 < candidates.count }

                if indices.isEmpty {
                    print(ANSIStyle.styled("No valid selections. Cancelled.", .yellow))
                    return
                }
                selected = indices.map { candidates[$0] }
            }

            // Final confirmation
            print()
            print("About to terminate \(selected.count) process(es). Continue? [y/N] ", terminator: "")
            fflush(stdout)
            guard let confirm = readLine()?.lowercased(), confirm == "y" || confirm == "yes" else {
                print(ANSIStyle.styled("Cancelled.", .dim))
                return
            }

            killProcesses(selected)
        } else {
            killProcesses(candidates)
        }
    }

    private func killProcesses(_ processes: [ProcessEntry]) {
        var killed = 0
        var failed = 0
        var freedBytes: UInt64 = 0

        for process in processes {
            let result = KillService.terminate(pid: process.pid)
            switch result {
            case .success:
                killed += 1
                freedBytes += process.memoryBytes
                print(ANSIStyle.styled("  Terminated: ", .green) + "\(process.name) (PID \(process.pid))")
            case .noPermission:
                failed += 1
                print(ANSIStyle.styled("  Permission denied: ", .red) + "\(process.name) (PID \(process.pid))")
            case .noSuchProcess:
                print(ANSIStyle.styled("  Already exited: ", .dim) + "\(process.name) (PID \(process.pid))")
            case .failed(let message):
                failed += 1
                print(ANSIStyle.styled("  Failed: ", .red) + "\(process.name) — \(message)")
            }
        }

        print()
        print(ANSIStyle.styled("Results: ", .bold) +
              ANSIStyle.styled("\(killed) terminated", .green) +
              (failed > 0 ? ", " + ANSIStyle.styled("\(failed) failed", .red) : "") +
              ", ~" + ANSIStyle.styled(ByteFormatter.format(freedBytes), .cyan) + " freed")
    }
}
