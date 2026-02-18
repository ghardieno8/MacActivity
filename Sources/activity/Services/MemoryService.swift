import Foundation
import Darwin

enum MemoryService {
    static func getStats() -> MemoryStats? {
        guard let vmStats = getVMStatistics() else { return nil }
        let pageSize = UInt64(vm_kernel_page_size)
        let totalBytes = getTotalMemory()

        let freeBytes = UInt64(vmStats.free_count) * pageSize
        let activeBytes = UInt64(vmStats.active_count) * pageSize
        let inactiveBytes = UInt64(vmStats.inactive_count) * pageSize
        let wiredBytes = UInt64(vmStats.wire_count) * pageSize
        let compressedBytes = UInt64(vmStats.compressor_page_count) * pageSize

        // App memory = internal pages - purgeable pages
        let internalBytes = UInt64(vmStats.internal_page_count) * pageSize
        let purgeableBytes = UInt64(vmStats.purgeable_count) * pageSize
        let appMemoryBytes = internalBytes > purgeableBytes ? internalBytes - purgeableBytes : 0

        let usedBytes = totalBytes > freeBytes ? totalBytes - freeBytes : 0

        // Memory pressure: used (excluding inactive cache) / total
        let pressureUsed = activeBytes + wiredBytes + compressedBytes
        let pressurePercentage = totalBytes > 0
            ? Double(pressureUsed) / Double(totalBytes) * 100.0
            : 0.0

        return MemoryStats(
            totalBytes: totalBytes,
            usedBytes: usedBytes,
            freeBytes: freeBytes,
            activeBytes: activeBytes,
            inactiveBytes: inactiveBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            appMemoryBytes: appMemoryBytes,
            pressurePercentage: min(pressurePercentage, 100.0)
        )
    }

    private static func getVMStatistics() -> vm_statistics64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    intPtr,
                    &count
                )
            }
        }

        return result == KERN_SUCCESS ? stats : nil
    }

    private static func getTotalMemory() -> UInt64 {
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return size
    }
}
