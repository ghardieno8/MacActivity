import Foundation
import Darwin

enum TUIApp {
    static func run() {
        let state = TUIState()
        let buf = ScreenBuffer()

        // Setup
        SignalHandler.install()
        RawMode.enable()
        print(ANSIEscape.enterAltScreen, terminator: "")
        print(ANSIEscape.hideCursor, terminator: "")
        fflush(stdout)

        defer { cleanup() }

        // Initial data load
        updateTerminalSize(state)
        state.refreshData()

        var lastRefresh = Date()
        let refreshInterval: TimeInterval = 2.0

        // Main loop
        while !SignalHandler.interrupted {
            // Handle resize
            if SignalHandler.resized {
                SignalHandler.resized = false
                updateTerminalSize(state)
                state.clampSelection()
            }

            // Poll input
            if let key = InputHandler.poll() {
                let shouldQuit = handleInput(key: key, state: state)
                if shouldQuit { break }
            }

            // Periodic data refresh
            let now = Date()
            if now.timeIntervalSince(lastRefresh) >= refreshInterval {
                state.refreshData()
                lastRefresh = now
            }

            // Render
            TUIRenderer.render(state: state, buf: buf)
            buf.flush()

            // Small sleep to avoid busy-waiting (input timeout handles most of this)
            usleep(10_000) // 10ms
        }
    }

    // MARK: - Input handling

    /// Returns true if the app should quit.
    private static func handleInput(key: KeyEvent, state: TUIState) -> Bool {
        switch state.mode {
        case .search:
            return handleSearchInput(key: key, state: state)
        case .confirm:
            return handleConfirmInput(key: key, state: state)
        case .normal:
            return handleNormalInput(key: key, state: state)
        }
    }

    private static func handleNormalInput(key: KeyEvent, state: TUIState) -> Bool {
        switch key {
        case .char("q"):
            return true

        case .up:
            state.selectedIndex -= 1
            state.clampSelection()

        case .down:
            state.selectedIndex += 1
            state.clampSelection()

        case .char("k"), .enter:
            let procs = state.displayProcesses
            guard state.selectedIndex < procs.count else { break }
            let p = procs[state.selectedIndex]
            if p.category == .critical {
                // Don't allow killing critical processes from TUI
                break
            }
            state.pendingAction = .killSingle(p)
            state.mode = .confirm

        case .char("f"):
            state.filter = state.filter.next()
            state.selectedIndex = 0
            state.scrollOffset = 0
            state.clampSelection()

        case .char("s"):
            state.sort = state.sort.next()
            state.clampSelection()

        case .char("/"):
            state.mode = .search
            state.searchQuery = ""

        case .char("c"):
            performCleanup(state: state)

        default:
            break
        }
        return false
    }

    private static func handleSearchInput(key: KeyEvent, state: TUIState) -> Bool {
        switch key {
        case .escape:
            state.mode = .normal
            state.searchQuery = ""
            state.selectedIndex = 0
            state.scrollOffset = 0
            state.clampSelection()

        case .enter:
            state.mode = .normal
            state.selectedIndex = 0
            state.scrollOffset = 0
            state.clampSelection()

        case .backspace:
            if !state.searchQuery.isEmpty {
                state.searchQuery.removeLast()
                state.selectedIndex = 0
                state.scrollOffset = 0
                state.clampSelection()
            }

        case .char(let ch):
            state.searchQuery.append(ch)
            state.selectedIndex = 0
            state.scrollOffset = 0
            state.clampSelection()

        default:
            break
        }
        return false
    }

    private static func handleConfirmInput(key: KeyEvent, state: TUIState) -> Bool {
        switch key {
        case .char("y"), .char("Y"):
            if let action = state.pendingAction {
                executeAction(action)
                state.refreshData()
            }
            state.pendingAction = nil
            state.mode = .normal

        case .char("n"), .char("N"), .escape:
            state.pendingAction = nil
            state.mode = .normal

        default:
            break // ignore other keys during confirmation
        }
        return false
    }

    // MARK: - Actions

    private static func executeAction(_ action: ConfirmAction) {
        switch action {
        case .killSingle(let process):
            _ = KillService.terminate(pid: process.pid)

        case .cleanupBatch(let processes, _):
            for process in processes {
                _ = KillService.terminate(pid: process.pid)
            }
        }
    }

    private static func performCleanup(state: TUIState) {
        let thresholdBytes: UInt64 = 50 * 1024 * 1024 // 50 MB
        let candidates = state.allProcesses
            .filter { $0.category == .safe && $0.memoryBytes >= thresholdBytes && !$0.isCurrentProcess }
            .sorted { $0.memoryBytes > $1.memoryBytes }

        guard !candidates.isEmpty else { return }

        let totalBytes = candidates.reduce(UInt64(0)) { $0 + $1.memoryBytes }
        state.pendingAction = .cleanupBatch(candidates, totalBytes)
        state.mode = .confirm
    }

    // MARK: - Helpers

    private static func updateTerminalSize(_ state: TUIState) {
        let size = SignalHandler.terminalSize()
        state.termWidth = size.width
        state.termHeight = size.height
    }

    private static func cleanup() {
        print(ANSIEscape.showCursor, terminator: "")
        print(ANSIEscape.leaveAltScreen, terminator: "")
        fflush(stdout)
        RawMode.disable()
    }
}
