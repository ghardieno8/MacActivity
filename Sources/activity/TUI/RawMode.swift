import Foundation
import Darwin

enum RawMode {
    private static var originalTermios = termios()
    private static var isRaw = false

    /// Enable raw mode: no echo, no canonical processing, min 0 bytes, 0 timeout.
    static func enable() {
        guard !isRaw else { return }
        tcgetattr(STDIN_FILENO, &originalTermios)
        var raw = originalTermios
        raw.c_lflag &= ~UInt(ECHO | ICANON | ISIG | IEXTEN)
        raw.c_iflag &= ~UInt(IXON | ICRNL)
        raw.c_cc.16 = 0  // VMIN
        raw.c_cc.17 = 1  // VTIME = 100ms
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        isRaw = true
    }

    /// Restore the terminal to its original settings.
    static func disable() {
        guard isRaw else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        isRaw = false
    }

    /// Non-blocking read of a single byte. Returns nil if nothing available.
    static func readByte() -> UInt8? {
        var byte: UInt8 = 0
        let n = read(STDIN_FILENO, &byte, 1)
        return n == 1 ? byte : nil
    }
}
