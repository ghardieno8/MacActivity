import Foundation

enum TUIRenderer {
    static func render(state: TUIState, buf: ScreenBuffer) {
        let w = state.termWidth

        buf.write(ANSIEscape.moveTo(row: 1, col: 1))
        buf.write(ANSIEscape.clearScreen)

        renderHeader(state: state, buf: buf, width: w)
        renderTable(state: state, buf: buf, width: w)
        renderFooter(state: state, buf: buf, width: w)
    }

    // MARK: - Header

    private static func renderHeader(state: TUIState, buf: ScreenBuffer, width: Int) {
        // Line 1: title + memory summary
        let title = ANSIColor.boldWhite.rawValue + " Activity Monitor" + ANSIColor.reset.rawValue
        var memInfo = ""
        if let stats = state.memoryStats {
            let pct = String(format: "%.0f%%", stats.pressurePercentage)
            let color: ANSIColor = stats.pressurePercentage < 50 ? .green :
                                   stats.pressurePercentage < 80 ? .yellow : .red
            let level = stats.pressurePercentage < 50 ? "Normal" :
                        stats.pressurePercentage < 80 ? "Warning" : "Critical"
            let barWidth = 15
            let filled = Int(stats.pressurePercentage / 100.0 * Double(barWidth))
            let bar = String(repeating: "█", count: filled) +
                      String(repeating: "░", count: barWidth - filled)
            memInfo = "Memory: " + stats.usedFormatted + "/" + stats.totalFormatted +
                      "  Pressure: " + color.rawValue + bar + " " + pct + " " + level +
                      ANSIColor.reset.rawValue
        }
        buf.writeLine(title + "  " + String(repeating: " ", count: max(0, width - 20 - VisibleString.visibleLength(memInfo))) + memInfo)

        // Line 2: filter / sort / count
        let processes = state.displayProcesses
        let filterLabel = "Showing: " + state.filter.label
        let sortLabel = "Sort: " + state.sort.label
        let countLabel = "\(processes.count) processes"
        var searchLabel = ""
        if state.mode == .search {
            searchLabel = "  Search: " + state.searchQuery + "▌"
        } else if !state.searchQuery.isEmpty {
            searchLabel = "  Search: \"" + state.searchQuery + "\""
        }

        buf.writeLine(ANSIColor.dim.rawValue + " " + filterLabel + "  │  " + sortLabel +
                       "  │  " + countLabel + searchLabel + ANSIColor.reset.rawValue)
    }

    // MARK: - Table

    private static func renderTable(state: TUIState, buf: ScreenBuffer, width: Int) {
        let processes = state.displayProcesses

        // Column widths
        let numW = 4
        let pidW = 8
        let memW = 10
        let catW = 10
        let fixedW = numW + pidW + memW + catW + 12 // 12 = gaps (5 columns × 2 + 2 padding)
        let remaining = max(20, width - fixedW)
        let nameW = remaining * 2 / 5
        let descW = remaining - nameW

        // Header line
        let hdr = " " +
            pad("#", numW, .right) + "  " +
            pad("PID", pidW, .right) + "  " +
            pad("Memory", memW, .right) + "  " +
            pad("Category", catW, .left) + "  " +
            pad("Name", nameW, .left) + "  " +
            pad("Description", descW, .left)
        buf.writeLine(ANSIColor.boldWhite.rawValue + hdr + ANSIColor.reset.rawValue)

        // Separator
        buf.writeLine(ANSIColor.dim.rawValue + " " + String(repeating: "─", count: min(width - 2, numW + pidW + memW + catW + nameW + descW + 10)) + ANSIColor.reset.rawValue)

        // Rows
        let visibleSlice = processes.dropFirst(state.scrollOffset).prefix(state.tableRows)
        for (dispIdx, process) in visibleSlice.enumerated() {
            let globalIdx = state.scrollOffset + dispIdx
            let isSelected = globalIdx == state.selectedIndex
            let num = "\(globalIdx + 1)"
            let pid = "\(process.pid)"
            let mem = process.memoryFormatted
            let cat = process.category.label
            let name = String(process.name.prefix(nameW))
            let desc = String(process.bundleInfo.prefix(descW))

            let catColor: ANSIColor = {
                switch process.category {
                case .safe: return .green
                case .caution: return .yellow
                case .critical: return .red
                }
            }()

            var row = " " +
                pad(num, numW, .right) + "  " +
                pad(pid, pidW, .right) + "  " +
                pad(mem, memW, .right) + "  " +
                catColor.rawValue + pad(cat, catW, .left) + ANSIColor.reset.rawValue + "  " +
                pad(name, nameW, .left) + "  " +
                ANSIColor.dim.rawValue + pad(desc, descW, .left) + ANSIColor.reset.rawValue

            if isSelected {
                // Reverse video for selected row
                row = ANSIColor.reverse.rawValue + stripColors(row) + ANSIColor.reset.rawValue
            }

            buf.writeLine(row)
        }

        // Fill remaining rows
        let rendered = visibleSlice.count
        for _ in rendered..<state.tableRows {
            buf.writeLine("")
        }
    }

    // MARK: - Footer

    private static func renderFooter(state: TUIState, buf: ScreenBuffer, width: Int) {
        switch state.mode {
        case .confirm:
            if let action = state.pendingAction {
                switch action {
                case .killSingle(let p):
                    let msg = " Kill \(p.name) (PID \(p.pid))? " +
                              ANSIColor.boldYellow.rawValue + "[y/n]" + ANSIColor.reset.rawValue
                    buf.write(ANSIColor.boldWhite.rawValue + msg + ANSIColor.reset.rawValue)
                case .cleanupBatch(let procs, let bytes):
                    let msg = " Kill \(procs.count) safe processes (~\(ByteFormatter.format(bytes)) reclaimable)? " +
                              ANSIColor.boldYellow.rawValue + "[y/n]" + ANSIColor.reset.rawValue
                    buf.write(ANSIColor.boldWhite.rawValue + msg + ANSIColor.reset.rawValue)
                }
            }
        case .search:
            buf.write(ANSIColor.dim.rawValue +
                       " Type to search, Esc to cancel" +
                       ANSIColor.reset.rawValue)
        case .normal:
            buf.write(ANSIColor.dim.rawValue +
                       " ↑↓:navigate  k:kill  f:filter  s:sort  /:search  c:cleanup  q:quit" +
                       ANSIColor.reset.rawValue)
        }
    }

    // MARK: - Helpers

    private enum Align { case left, right }

    private static func pad(_ text: String, _ width: Int, _ align: Align) -> String {
        let t = text.count > width ? String(text.prefix(width - 1)) + "…" : text
        switch align {
        case .left:
            return t.padding(toLength: width, withPad: " ", startingAt: 0)
        case .right:
            return String(repeating: " ", count: max(0, width - t.count)) + t
        }
    }

    private static func stripColors(_ text: String) -> String {
        VisibleString.stripANSI(text)
    }
}
