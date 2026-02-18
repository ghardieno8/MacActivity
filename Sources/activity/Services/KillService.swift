import Foundation
import Darwin

enum KillResult {
    case success
    case noPermission
    case noSuchProcess
    case failed(String)
}

enum KillService {
    static func terminate(pid: pid_t) -> KillResult {
        let result = kill(pid, SIGTERM)
        if result == 0 {
            return .success
        }
        return mapError(errno)
    }

    static func forceKill(pid: pid_t) -> KillResult {
        let result = kill(pid, SIGKILL)
        if result == 0 {
            return .success
        }
        return mapError(errno)
    }

    private static func mapError(_ err: Int32) -> KillResult {
        switch err {
        case EPERM:
            return .noPermission
        case ESRCH:
            return .noSuchProcess
        default:
            return .failed(String(cString: strerror(err)))
        }
    }
}
