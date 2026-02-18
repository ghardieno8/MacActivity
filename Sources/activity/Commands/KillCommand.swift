import ArgumentParser
import Foundation

struct KillCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kill",
        abstract: "Terminate a process by PID"
    )

    @Argument(help: "Process ID to terminate")
    var pid: Int32

    @Flag(name: .shortAndLong, help: "Force kill (SIGKILL instead of SIGTERM)")
    var force: Bool = false

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var yes: Bool = false

    func run() throws {
        try KillHelper.killWithInfo(pid: pid, force: force, skipConfirm: yes)
    }
}
