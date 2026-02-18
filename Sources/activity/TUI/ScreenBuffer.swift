import Foundation

/// Buffered screen writer — collects output and flushes once per frame.
final class ScreenBuffer {
    private var buffer = ""

    func write(_ text: String) {
        buffer += text
    }

    func writeLine(_ text: String = "") {
        buffer += text + "\n"
    }

    func flush() {
        guard !buffer.isEmpty else { return }
        Swift.print(buffer, terminator: "")
        fflush(stdout)
        buffer = ""
    }
}

/// ANSI escape helpers for TUI rendering.
enum ANSIEscape {
    static let enterAltScreen = "\u{1B}[?1049h"
    static let leaveAltScreen = "\u{1B}[?1049l"
    static let hideCursor = "\u{1B}[?25l"
    static let showCursor = "\u{1B}[?25h"
    static let clearScreen = "\u{1B}[2J"
    static let resetAttributes = "\u{1B}[0m"

    static func moveTo(row: Int, col: Int) -> String {
        "\u{1B}[\(row);\(col)H"
    }

    static func clearLine() -> String {
        "\u{1B}[2K"
    }
}
