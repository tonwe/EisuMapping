import AppKit
import ApplicationServices
import KeyMapping

/// Keep AX requests away from the event tap's main run loop. Retain the window
/// order so raising a window doesn't turn repeated presses into a two-window toggle.
actor WindowSwitcher {
    private var applicationPID: pid_t?
    private var orderedWindows: [AXUIElement] = []

    func switchWindow(pid: pid_t, direction: KeyMapping.Direction) async -> String {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, 1)
        var windowValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &windowValue)
        guard error == .success, let windows = windowValue as? [AXUIElement] else {
            return "无法读取窗口（\(error.rawValue)）"
        }
        let available = windows.filter { window in
            let role: String? = attribute(window, kAXRoleAttribute)
            let subrole: String? = attribute(window, kAXSubroleAttribute)
            let minimized: Bool? = attribute(window, kAXMinimizedAttribute)
            let modal: Bool? = attribute(window, kAXModalAttribute)
            return WindowEligibility.isSwitchable(role: role, subrole: subrole, minimized: minimized, modal: modal)
        }

        if applicationPID != pid {
            applicationPID = pid
            orderedWindows = []
        }
        orderedWindows.removeAll { previous in !available.contains { CFEqual(previous, $0) } }
        for window in available where !orderedWindows.contains(where: { CFEqual(window, $0) }) {
            orderedWindows.append(window)
        }

        var focused: AXUIElement? = attribute(application, kAXFocusedWindowAttribute)
        if focused == nil { focused = attribute(application, kAXMainWindowAttribute) }
        if let focused {
            let modal: Bool? = attribute(focused, kAXModalAttribute)
            let children: [AXUIElement] = attribute(focused, kAXChildrenAttribute) ?? []
            let hasSheet = children.contains { child in
                let role: String? = attribute(child, kAXRoleAttribute)
                return role == kAXSheetRole
            }
            if modal == true || hasSheet { return "请先关闭对话框" }
        }
        let current = focused.flatMap { focused in
            orderedWindows.firstIndex { CFEqual($0, focused) }
        }
        guard let index = WindowCycle.destination(count: orderedWindows.count, current: current, direction: direction)
        else {
            return orderedWindows.isEmpty ? "未找到可切换的窗口" : "只有一个可切换窗口"
        }
        let target = orderedWindows[index]
        let count = orderedWindows.count

        // Do not bring the old app forward if the user switched apps during AX work.
        let stillFrontmost = await MainActor.run {
            NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
        }
        guard stillFrontmost, !Task.isCancelled else { return "当前应用已改变，已取消切换" }

        AXUIElementSetAttributeValue(target, kAXMainAttribute as CFString, kCFBooleanTrue)
        let raiseError = AXUIElementPerformAction(target, kAXRaiseAction as CFString)
        guard raiseError == .success else { return "应用未响应切换（\(raiseError.rawValue)）" }
        AXUIElementSetAttributeValue(target, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        return "已切换（\(index + 1)/\(count)）"
    }

    private func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }
}
