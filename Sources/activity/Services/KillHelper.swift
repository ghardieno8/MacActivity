import ArgumentParser
import Foundation

enum KillHelper {
    /// Display process info and execute kill with optional confirmation.
    /// Used by both KillCommand (CLI) and TUI.
    static func killWithInfo(
        pid: pid_t,
        force: Bool = false,
        skipConfirm: Bool = false
    ) throws {
        guard let process = ProcessService.getProcessEntry(pid: pid) else {
            print(ANSIStyle.styled("Error: No process found with PID \(pid).", .red))
            throw ExitCode.failure
        }

        let category = CategoryService.categorize(process)

        // Show process info
        print(ANSIStyle.styled("Process: ", .bold) + process.name)
        print(ANSIStyle.styled("PID:     ", .bold) + "\(process.pid)")
        print(ANSIStyle.styled("Memory:  ", .bold) + process.memoryFormatted)
        print(ANSIStyle.styled("Category:", .bold) + " \(category.coloredLabel)")

        if !process.path.isEmpty {
            print(ANSIStyle.styled("Path:    ", .bold) + ANSIStyle.styled(process.path, .dim))
        }
        print()

        // Warn about critical/caution processes
        if category == .critical {
            print(ANSIStyle.styled("WARNING: This is a system-critical process!", .boldRed))
            print(ANSIStyle.styled("Killing it may cause system instability or crash.", .red))
            print()
        } else if category == .caution {
            print(ANSIStyle.styled("Note: This is an Apple system service. Proceed with caution.", .yellow))
            print()
        }

        // Confirm
        if !skipConfirm {
            let signal = force ? "SIGKILL (force)" : "SIGTERM"
            print("Send \(signal) to \(process.name) (PID \(pid))? [y/N] ", terminator: "")
            fflush(stdout)
            guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
                print(ANSIStyle.styled("Cancelled.", .dim))
                return
            }
        }

        // Kill
        let result = force ? KillService.forceKill(pid: pid) : KillService.terminate(pid: pid)
        try handleResult(result, process: process, force: force, pid: pid)
    }

    static func handleResult(_ result: KillResult, process: ProcessEntry, force: Bool, pid: pid_t) throws {
        switch result {
        case .success:
            let method = force ? "Force killed" : "Terminated"
            print(ANSIStyle.styled("\(method) \(process.name) (PID \(pid)).", .green))
        case .noPermission:
            print(ANSIStyle.styled("Error: Permission denied. Try running with sudo.", .red))
            throw ExitCode.failure
        case .noSuchProcess:
            print(ANSIStyle.styled("Error: Process no longer exists.", .yellow))
        case .failed(let message):
            print(ANSIStyle.styled("Error: \(message)", .red))
            throw ExitCode.failure
        }
    }
}
