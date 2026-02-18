import Foundation

enum VisibleString {
    /// Strip all ANSI escape sequences from a string.
    static func stripANSI(_ text: String) -> String {
        text.replacingOccurrences(
            of: "\u{1B}\\[[0-9;]*m",
            with: "",
            options: .regularExpression
        )
    }

    /// Return the visible (non-ANSI) character count.
    static func visibleLength(_ text: String) -> Int {
        stripANSI(text).count
    }

    /// Pad or truncate `text` to exactly `width` visible characters,
    /// preserving embedded ANSI codes.
    static func fit(_ text: String, width: Int) -> String {
        let visible = stripANSI(text)
        let vLen = visible.count

        if vLen == width {
            return text
        } else if vLen < width {
            // Pad on the right
            return text + String(repeating: " ", count: width - vLen)
        } else {
            // Truncate: walk the original string, counting only visible chars
            var result = ""
            var visCount = 0
            var i = text.startIndex
            while i < text.endIndex && visCount < width - 1 {
                if text[i] == "\u{1B}" {
                    // Copy entire escape sequence
                    let seqStart = i
                    i = text.index(after: i)
                    if i < text.endIndex && text[i] == "[" {
                        i = text.index(after: i)
                        while i < text.endIndex && text[i] != "m" {
                            i = text.index(after: i)
                        }
                        if i < text.endIndex {
                            i = text.index(after: i) // skip 'm'
                        }
                    }
                    result += String(text[seqStart..<i])
                } else {
                    result.append(text[i])
                    visCount += 1
                    i = text.index(after: i)
                }
            }
            result += "…"
            result += ANSIColor.reset.rawValue
            return result
        }
    }
}
