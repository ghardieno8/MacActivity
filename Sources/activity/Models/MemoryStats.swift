import Foundation

struct MemoryStats {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let freeBytes: UInt64
    let activeBytes: UInt64
    let inactiveBytes: UInt64
    let wiredBytes: UInt64
    let compressedBytes: UInt64
    let appMemoryBytes: UInt64
    let pressurePercentage: Double

    var totalFormatted: String { ByteFormatter.format(totalBytes) }
    var usedFormatted: String { ByteFormatter.format(usedBytes) }
    var freeFormatted: String { ByteFormatter.format(freeBytes) }
    var activeFormatted: String { ByteFormatter.format(activeBytes) }
    var inactiveFormatted: String { ByteFormatter.format(inactiveBytes) }
    var wiredFormatted: String { ByteFormatter.format(wiredBytes) }
    var compressedFormatted: String { ByteFormatter.format(compressedBytes) }
    var appMemoryFormatted: String { ByteFormatter.format(appMemoryBytes) }

    var pressureLevel: String {
        if pressurePercentage < 50 {
            return ANSIStyle.styled("Normal", .green)
        } else if pressurePercentage < 80 {
            return ANSIStyle.styled("Warning", .yellow)
        } else {
            return ANSIStyle.styled("Critical", .red)
        }
    }

    var pressureBar: String {
        let width = 30
        let filled = Int(pressurePercentage / 100.0 * Double(width))
        let empty = width - filled

        let color: ANSIColor = pressurePercentage < 50 ? .green :
                                pressurePercentage < 80 ? .yellow : .red

        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        let percentage = String(format: "%.1f%%", pressurePercentage)
        return ANSIStyle.styled(bar, color) + " " + percentage
    }
}
