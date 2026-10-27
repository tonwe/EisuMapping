import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLogin {
    enum State {
        case disabled
        case enabled
        case requiresApproval
    }

    private enum RegistrationError: LocalizedError {
        case notInstalled

        var errorDescription: String? {
            "请先将 EisuMapping 移到「应用程序」文件夹，再开启开机启动。"
        }
    }

    var state: State {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        default: .disabled
        }
    }

    func toggle() async throws {
        let location = Bundle.main.bundleURL.standardizedFileURL
        let applications = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
        ]
        guard location.pathExtension == "app",
            applications.contains(location.deletingLastPathComponent())
        else {
            throw RegistrationError.notInstalled
        }
        switch state {
        case .enabled, .requiresApproval:
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                SMAppService.mainApp.unregister { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        case .disabled:
            do {
                try SMAppService.mainApp.register()
            } catch {
                guard state == .requiresApproval else { throw error }
            }
            if state == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        }
    }
}
