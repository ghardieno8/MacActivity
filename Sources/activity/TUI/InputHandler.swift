import Foundation

enum KeyEvent: Equatable {
    case up
    case down
    case enter
    case char(Character)
    case escape
    case backspace
    case unknown
}

enum InputHandler {
    /// Read available bytes and parse into a KeyEvent.
    /// Returns nil if no input is available.
    static func poll() -> KeyEvent? {
        guard let b = RawMode.readByte() else { return nil }

        switch b {
        case 0x1B: // ESC or escape sequence
            guard let b2 = RawMode.readByte() else { return .escape }
            if b2 == UInt8(ascii: "[") {
                guard let b3 = RawMode.readByte() else { return .escape }
                switch b3 {
                case UInt8(ascii: "A"): return .up
                case UInt8(ascii: "B"): return .down
                default: return .unknown
                }
            }
            return .escape

        case 0x0D, 0x0A: // CR or LF
            return .enter

        case 0x7F, 0x08: // DEL or BS
            return .backspace

        case 0x03: // Ctrl-C
            return .char("q") // treat as quit

        default:
            if b >= 0x20 && b < 0x7F {
                return .char(Character(UnicodeScalar(b)))
            }
            return .unknown
        }
    }
}
