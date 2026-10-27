import AppKit
import ApplicationServices
import KeyMapping

// The event tap and all state run on the main run loop.
@MainActor
final class KeyboardMapper {
    private var mapping = KeyMapping()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let windowSwitcher = WindowSwitcher()
    var onStatusChange: ((String) -> Void)?
    private(set) var lastStatus = "尚未检测到英数 / かな按键"

    private func report(_ message: String) {
        lastStatus = message
        onStatusChange?(message)
    }

    var isEnabled: Bool {
        get { mapping.isEnabled }
        set { mapping.isEnabled = newValue }
    }

    var isRunning: Bool {
        guard let tap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    func start() -> Bool {
        guard AccessibilityPermission.isGranted else {
            stop()
            return false
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
            return isRunning
        }

        let mask =
            (CGEventMask(1) << CGEventType.keyDown.rawValue)
            | (CGEventMask(1) << CGEventType.keyUp.rawValue)
        guard
            let newTap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: { _, type, event, context in
                    guard let context else { return Unmanaged.passUnretained(event) }
                    let shouldSuppress = MainActor.assumeIsolated {
                        let mapper = Unmanaged<KeyboardMapper>.fromOpaque(context).takeUnretainedValue()
                        return mapper.handle(type: type, event: event)
                    }
                    return shouldSuppress ? nil : Unmanaged.passUnretained(event)
                },
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        else { return false }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0) else {
            CFMachPortInvalidate(newTap)
            return false
        }
        tap = newTap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        mapping.reset()
    }

    private func handle(type: CGEventType, event: CGEvent) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            mapping.reset()
            if let tap, AccessibilityPermission.isGranted {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return false
        }
        guard type == .keyDown || type == .keyUp else {
            return false
        }

        let modifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn]
        let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
        let action = mapping.handle(
            keyCode: keyCode,
            isKeyDown: type == .keyDown,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
            hasModifiers: !event.flags.intersection(modifiers).isEmpty
        )

        switch action {
        case .passThrough:
            if type == .keyDown, keyCode == 0x66 || keyCode == 0x68, isEnabled {
                report("已收到按键，组合键保持原样")
            }
            return false
        case .suppress:
            return true
        case .switchWindow(let direction):
            let keyName = keyCode == 0x66 ? "英数" : "かな"
            report("已收到\(keyName)，正在切换窗口")
            if let application = NSWorkspace.shared.frontmostApplication {
                let pid = application.processIdentifier
                let name = application.localizedName ?? "当前应用"
                // AX work runs outside the event tap on the switcher's actor.
                Task {
                    let result = await windowSwitcher.switchWindow(pid: pid, direction: direction)
                    report("\(keyName) · \(name)：\(result)")
                }
            } else {
                report("已收到\(keyName)，未找到当前应用")
            }
            return true
        }
    }
}
