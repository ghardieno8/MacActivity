import Foundation
import Darwin

// Global sig_atomic_t flags — safe to write from signal handlers.
private var gResized: sig_atomic_t = 0
private var gInterrupted: sig_atomic_t = 0

enum SignalHandler {
    static var resized: Bool {
        get { gResized != 0 }
        set { gResized = newValue ? 1 : 0 }
    }

    static var interrupted: Bool {
        get { gInterrupted != 0 }
        set { gInterrupted = newValue ? 1 : 0 }
    }

    static func install() {
        signal(SIGWINCH) { _ in gResized = 1 }
        signal(SIGINT) { _ in gInterrupted = 1 }
    }

    /// Returns (columns, rows) of the terminal.
    static func terminalSize() -> (width: Int, height: Int) {
        var ws = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 {
            return (Int(ws.ws_col), Int(ws.ws_row))
        }
        return (80, 24)
    }
}
