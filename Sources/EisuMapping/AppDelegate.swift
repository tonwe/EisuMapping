import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let mapper = KeyboardMapper()
    private let launchAtLogin = LaunchAtLogin()
    private var statusItem: NSStatusItem?
    private let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let detailItem = NSMenuItem(title: "尚未检测到英数 / かな按键", action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "暂停映射", action: #selector(toggleMapping), keyEquivalent: "")
    private let permissionItem = NSMenuItem(
        title: "授予辅助功能权限…", action: #selector(openAccessibility), keyEquivalent: ""
    )
    private let loginItem = NSMenuItem(title: "开机启动", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private var permissionTimer: Timer?
    private var loginItemTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A second launch should not install a second event tap.
        if let identifier = Bundle.main.bundleIdentifier,
            NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
                .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier })
        {
            NSApp.terminate(nil)
            return
        }

        configureMenu()
        mapper.onStatusChange = { [weak self] message in
            self?.detailItem.title = message
        }
        refresh()
        AccessibilityPermission.request()
    }

    private func configureMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image =
            NSImage(systemSymbolName: "rectangle.2.swap", accessibilityDescription: "EisuMapping")
            ?? NSImage(systemSymbolName: "keyboard", accessibilityDescription: "EisuMapping")
        image?.isTemplate = true
        item.button?.image = image

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(stateItem)
        menu.addItem(detailItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "英数 → 当前应用的上一个窗口", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "かな → 当前应用的下一个窗口", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        toggleItem.target = self
        permissionItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(permissionItem)
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 EisuMapping", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        for item in menu.items where item.action == nil { item.isEnabled = false }
        item.menu = menu
        statusItem = item
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        loginItemTask?.cancel()
        mapper.stop()
    }

    private func refresh() {
        guard let statusItem else { return }
        let trusted = AccessibilityPermission.isGranted
        let running = mapper.start()
        detailItem.title = trusted ? mapper.lastStatus : "开关已开启时，请移除旧条目后重新添加本应用"
        if !trusted {
            stateItem.title = "等待辅助功能权限"
        } else if !running {
            stateItem.title = "键盘监听未启动，请退出后重试"
        } else {
            stateItem.title = mapper.isEnabled ? "映射已启用" : "映射已暂停"
        }
        toggleItem.title = mapper.isEnabled ? "暂停映射" : "启用映射"
        toggleItem.isEnabled = running
        permissionItem.isHidden = trusted && running
        statusItem.button?.appearsDisabled = !running || !mapper.isEnabled
        statusItem.button?.toolTip = "EisuMapping · \(stateItem.title)"
        switch launchAtLogin.state {
        case .disabled:
            loginItem.title = "开机启动"
            loginItem.state = .off
        case .enabled:
            loginItem.title = "开机启动"
            loginItem.state = .on
        case .requiresApproval:
            loginItem.title = "开机启动（待系统允许）"
            loginItem.state = .mixed
        }
        loginItem.isEnabled = loginItemTask == nil

        // Only poll while waiting for permission; normal operation is event driven.
        if !running, permissionTimer == nil {
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        } else if running {
            permissionTimer?.invalidate()
            permissionTimer = nil
        }
    }

    @objc private func toggleMapping() {
        mapper.isEnabled.toggle()
        refresh()
    }

    @objc private func openAccessibility() {
        AccessibilityPermission.openSettings()
    }

    @objc private func toggleLaunchAtLogin() {
        guard loginItemTask == nil else { return }
        loginItem.isEnabled = false
        loginItemTask = Task {
            defer {
                loginItemTask = nil
                refresh()
            }
            do {
                try await launchAtLogin.toggle()
            } catch {
                let alert = NSAlert()
                alert.messageText = "无法更改开机启动设置"
                alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: "好")
                NSApp.activate(ignoringOtherApps: true)
                alert.runModal()
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
