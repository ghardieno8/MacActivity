import Foundation
import Darwin

enum ProcessService {
    static func listAll() -> [ProcessEntry] {
        // Use sysctl KERN_PROC_ALL to enumerate all processes visible to the
        // current user — proc_listallpids only returns the caller's own PIDs
        // on modern macOS without root.
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size: Int = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0, size > 0 else {
            return []
        }

        let stride = MemoryLayout<kinfo_proc>.stride
        let count = size / stride
        let buffer = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: count)
        defer { buffer.deallocate() }

        guard sysctl(&mib, UInt32(mib.count), buffer, &size, nil, 0) == 0 else {
            return []
        }

        let actualCount = size / stride
        var entries: [ProcessEntry] = []
        entries.reserveCapacity(actualCount)

        for i in 0..<actualCount {
            let kp = buffer[i]
            let pid = kp.kp_proc.p_pid
            guard pid > 0 else { continue }

            let entry = makeEntry(pid: pid, kp: kp)
            entries.append(entry)
        }

        return entries
    }

    /// Build a ProcessEntry from sysctl kinfo_proc, enriching with proc_pidinfo
    /// where available.
    private static func makeEntry(pid: pid_t, kp: kinfo_proc) -> ProcessEntry {
        let uid = kp.kp_eproc.e_ucred.cr_uid

        // Name: try proc_name, fall back to kinfo_proc p_comm
        let name: String = {
            var nameBuffer = [CChar](repeating: 0, count: Int(MAXCOMLEN) + 1)
            let nameLen = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            if nameLen > 0 {
                return String(cString: nameBuffer)
            }
            return withUnsafePointer(to: kp.kp_proc.p_comm) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) { cStr in
                    String(cString: cStr)
                }
            }
        }()

        let path = getProcessPath(pid: pid)

        // Memory: try PROC_PIDTASKALLINFO first, then PROC_PIDTASKINFO
        var memoryBytes: UInt64 = 0
        var taskAllInfo = proc_taskallinfo()
        let taskAllSize = Int32(MemoryLayout<proc_taskallinfo>.size)
        if proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, &taskAllInfo, taskAllSize) == taskAllSize {
            memoryBytes = UInt64(taskAllInfo.ptinfo.pti_resident_size)
        } else {
            var taskInfo = proc_taskinfo()
            let taskSize = Int32(MemoryLayout<proc_taskinfo>.size)
            if proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskSize) == taskSize {
                memoryBytes = UInt64(taskInfo.pti_resident_size)
            }
        }

        let bundleInfo = Self.extractBundleInfo(from: path)

        return ProcessEntry(
            pid: pid, name: name.isEmpty ? "unknown" : name, path: path,
            memoryBytes: memoryBytes, uid: uid, category: .safe,
            bundleInfo: bundleInfo
        )
    }

    static func getProcessEntry(pid: pid_t) -> ProcessEntry? {
        // Use sysctl to look up a single PID.
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var kp = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, UInt32(mib.count), &kp, &size, nil, 0) == 0,
              size > 0 else {
            return nil
        }
        return makeEntry(pid: pid, kp: kp)
    }

    private static func extractBundleInfo(from path: String) -> String {
        guard let range = path.range(of: ".app", options: .literal) else {
            return ""
        }
        let bundleRoot = String(path[...range.upperBound])
        let plistPath = bundleRoot + "/Contents/Info.plist"
        guard let plist = NSDictionary(contentsOfFile: plistPath) else {
            return ""
        }
        if let info = plist["CFBundleGetInfoString"] as? String, !info.isEmpty {
            return info
        }
        if let copyright = plist["NSHumanReadableCopyright"] as? String, !copyright.isEmpty {
            return copyright
        }
        if let identifier = plist["CFBundleIdentifier"] as? String, !identifier.isEmpty {
            return identifier
        }
        return ""
    }

    private static func getProcessPath(pid: pid_t) -> String {
        var pathBuffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        let pathLen = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
        if pathLen > 0 {
            return String(cString: pathBuffer)
        }
        return ""
    }
}
