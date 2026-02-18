import ArgumentParser
import Foundation

struct MonitorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "monitor",
        abstract: "Interactive TUI for browsing and managing processes"
    )

    func run() throws {
        guard isatty(STDIN_FILENO) != 0 && isatty(STDOUT_FILENO) != 0 else {
            print(ANSIStyle.styled("Error: Interactive monitor requires a terminal.", .red))
            print("Use 'activity top' for non-interactive output.")
            throw ExitCode.failure
        }
        TUIApp.run()
    }
}
