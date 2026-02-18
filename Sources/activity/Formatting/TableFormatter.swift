import Foundation

struct Column {
    let header: String
    let width: Int
    let alignment: Alignment

    enum Alignment {
        case left
        case right
    }

    func format(_ value: String) -> String {
        let truncated = value.count > width ? String(value.prefix(width - 1)) + "…" : value
        switch alignment {
        case .left:
            return truncated.padding(toLength: width, withPad: " ", startingAt: 0)
        case .right:
            let padding = max(0, width - truncated.count)
            return String(repeating: " ", count: padding) + truncated
        }
    }
}

enum TableFormatter {
    static func printProcessTable(_ processes: [ProcessEntry]) {
        let columns = [
            Column(header: "PID", width: 7, alignment: .right),
            Column(header: "Memory", width: 10, alignment: .right),
            Column(header: "Category", width: 10, alignment: .left),
            Column(header: "Name", width: 30, alignment: .left),
            Column(header: "Description", width: 50, alignment: .left),
        ]

        // Print header
        let header = columns.map { ANSIStyle.styled($0.format($0.header), .boldWhite) }
            .joined(separator: "  ")
        print(header)

        let separator = columns.map { String(repeating: "─", count: $0.width) }
            .joined(separator: "  ")
        print(ANSIStyle.styled(separator, .dim))

        // Print rows
        for process in processes {
            let row = [
                columns[0].format("\(process.pid)"),
                ANSIStyle.styled(columns[1].format(process.memoryFormatted), .cyan),
                process.category.coloredLabel.padding(toLength: columns[2].width + 9, withPad: " ", startingAt: 0),
                columns[3].format(process.name),
                ANSIStyle.styled(columns[4].format(process.bundleInfo), .dim),
            ].joined(separator: "  ")
            print(row)
        }
    }

    static func printNumberedProcessTable(_ processes: [ProcessEntry]) {
        let columns = [
            Column(header: "#", width: 4, alignment: .right),
            Column(header: "PID", width: 7, alignment: .right),
            Column(header: "Memory", width: 10, alignment: .right),
            Column(header: "Category", width: 10, alignment: .left),
            Column(header: "Name", width: 30, alignment: .left),
            Column(header: "Description", width: 40, alignment: .left),
        ]

        let header = columns.map { ANSIStyle.styled($0.format($0.header), .boldWhite) }
            .joined(separator: "  ")
        print(header)

        let separator = columns.map { String(repeating: "─", count: $0.width) }
            .joined(separator: "  ")
        print(ANSIStyle.styled(separator, .dim))

        for (i, process) in processes.enumerated() {
            let row = [
                columns[0].format("\(i + 1)"),
                columns[1].format("\(process.pid)"),
                ANSIStyle.styled(columns[2].format(process.memoryFormatted), .cyan),
                process.category.coloredLabel.padding(toLength: columns[3].width + 9, withPad: " ", startingAt: 0),
                columns[4].format(process.name),
                ANSIStyle.styled(columns[5].format(process.bundleInfo), .dim),
            ].joined(separator: "  ")
            print(row)
        }
    }
}
