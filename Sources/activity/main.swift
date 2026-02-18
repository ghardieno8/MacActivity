import ArgumentParser

struct Activity: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "activity",
        abstract: "macOS Memory Monitor — view processes, memory stats, and clean up",
        version: "1.0.0",
        subcommands: [
            MonitorCommand.self,
            TopCommand.self,
            StatsCommand.self,
            KillCommand.self,
            CleanupCommand.self,
        ],
        defaultSubcommand: MonitorCommand.self
    )
}

Activity.main()
