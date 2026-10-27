import AppKit
import KeyMapping

@MainActor
enum ApplicationSwitcher {
    static func switchApplication(_ direction: KeyMapping.Direction) -> String {
        let workspace = NSWorkspace.shared
        let applications = workspace.runningApplications
            .filter { $0.activationPolicy == .regular && !$0.isTerminated }
            .sorted {
                let left = $0.launchDate ?? .distantPast
                let right = $1.launchDate ?? .distantPast
                return left == right ? $0.processIdentifier < $1.processIdentifier : left < right
            }
        guard let frontmost = workspace.frontmostApplication else { return "未找到当前应用" }
        let current = applications.firstIndex { $0.isEqual(frontmost) }
        guard let index = SwitchCycle.destination(count: applications.count, current: current, direction: direction)
        else {
            return "没有其他可切换的应用"
        }

        let target = applications[index]
        let name = target.localizedName ?? "目标应用"
        return target.activate(options: []) ? "切换到\(name)" : "无法切换到\(name)"
    }
}
