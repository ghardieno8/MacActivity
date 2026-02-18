import Foundation

enum ANSIColor: String {
    case red = "\u{1B}[31m"
    case green = "\u{1B}[32m"
    case yellow = "\u{1B}[33m"
    case blue = "\u{1B}[34m"
    case magenta = "\u{1B}[35m"
    case cyan = "\u{1B}[36m"
    case white = "\u{1B}[37m"
    case gray = "\u{1B}[90m"
    case bold = "\u{1B}[1m"
    case dim = "\u{1B}[2m"
    case reset = "\u{1B}[0m"

    case boldRed = "\u{1B}[1;31m"
    case boldGreen = "\u{1B}[1;32m"
    case boldYellow = "\u{1B}[1;33m"
    case boldCyan = "\u{1B}[1;36m"
    case boldWhite = "\u{1B}[1;37m"
    case reverse = "\u{1B}[7m"
}

extension String {
    func colored(_ color: ANSIColor) -> String {
        "\(color.rawValue)\(self)\(ANSIColor.reset.rawValue)"
    }
}

enum ANSIStyle {
    private static var colorEnabled: Bool {
        isatty(STDOUT_FILENO) != 0
    }

    static func styled(_ text: String, _ color: ANSIColor) -> String {
        colorEnabled ? text.colored(color) : text
    }
}
