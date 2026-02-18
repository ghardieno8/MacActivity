import Foundation

struct ProcessEntry {
    let pid: pid_t
    let name: String
    let path: String
    let memoryBytes: UInt64
    let uid: uid_t
    var category: SafetyCategory
    var bundleInfo: String = ""

    var memoryFormatted: String {
        ByteFormatter.format(memoryBytes)
    }

    var isCurrentProcess: Bool {
        pid == getpid()
    }
}
