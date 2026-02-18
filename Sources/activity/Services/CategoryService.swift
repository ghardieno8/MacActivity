import Foundation

enum CategoryService {
    // System-critical processes that should never be killed
    private static let criticalNames: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "loginwindow",
        "opendirectoryd", "coreduetd", "configd", "distnoted",
        "logd", "UserEventAgent", "syslogd", "notifyd",
        "mds", "mds_stores", "diskarbitrationd", "securityd",
        "trustd", "bluetoothd", "airportd", "powerd",
        "hidd", "coreaudiod", "audiod", "CommCenter",
        "symptomsd", "CloudKeychainProxy", "secd",
    ]

    // Apple user-space services (caution)
    private static let cautionNames: Set<String> = [
        "Finder", "Dock", "SystemUIServer", "Spotlight",
        "NotificationCenter", "ControlCenter", "WiFiAgent",
        "AirPlayUIAgent", "Siri", "SiriNCService",
        "universalaccessd", "talagent", "pboard",
        "sharingd", "rapportd", "AMPDeviceDiscoveryAgent",
        "bird", "cloudd", "nsurlsessiond", "lsd",
        "iconservicesagent", "containermanagerd",
    ]

    // Critical path prefixes
    private static let criticalPaths: [String] = [
        "/System/",
        "/usr/libexec/",
        "/usr/sbin/",
    ]

    // Caution path prefixes
    private static let cautionPaths: [String] = [
        "/System/Library/CoreServices/",
        "/System/Library/PrivateFrameworks/",
    ]

    static func categorize(_ entry: ProcessEntry) -> SafetyCategory {
        // PID 0 and 1 are always critical
        if entry.pid <= 1 {
            return .critical
        }

        // Root-owned processes are critical
        if entry.uid == 0 {
            return .critical
        }

        // Check by name
        if criticalNames.contains(entry.name) {
            return .critical
        }
        if cautionNames.contains(entry.name) {
            return .caution
        }

        // Check by path
        if !entry.path.isEmpty {
            for prefix in criticalPaths {
                if entry.path.hasPrefix(prefix) {
                    // But if it's under CoreServices, it's caution not critical
                    for cautionPrefix in cautionPaths {
                        if entry.path.hasPrefix(cautionPrefix) {
                            return .caution
                        }
                    }
                    return .critical
                }
            }

            // User applications
            if entry.path.hasPrefix("/Applications/") ||
               entry.path.contains(".app/") {
                return .safe
            }

            // Homebrew / user-installed
            if entry.path.hasPrefix("/usr/local/") ||
               entry.path.hasPrefix("/opt/homebrew/") {
                return .safe
            }

            // User home directory
            if entry.path.hasPrefix("/Users/") {
                return .safe
            }
        }

        // Default: caution for anything we can't clearly categorize
        return .caution
    }

    static func categorizeAll(_ entries: [ProcessEntry]) -> [ProcessEntry] {
        entries.map { entry in
            var categorized = entry
            categorized.category = categorize(entry)
            return categorized
        }
    }
}
