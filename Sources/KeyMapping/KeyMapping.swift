/// Only unmodified JIS Eisu/Kana presses are mapped. Their corresponding
/// releases must still be swallowed if modifiers or enabled state change.
public struct KeyMapping {
    public enum Direction: Equatable, Sendable {
        case previous
        case next
    }

    public enum Action: Equatable, Sendable {
        case passThrough
        case suppress
        case switchWindow(Direction)
    }

    public var isEnabled = true
    private var capturedKeys: Set<UInt16> = []

    public init() {}

    public mutating func handle(
        keyCode: UInt16, isKeyDown: Bool, isRepeat: Bool, hasModifiers: Bool
    ) -> Action {
        guard keyCode == 0x66 || keyCode == 0x68 else { return .passThrough }

        if !isKeyDown {
            return capturedKeys.remove(keyCode) != nil ? .suppress : .passThrough
        }
        if capturedKeys.contains(keyCode) { return .suppress }
        guard isEnabled, !hasModifiers, !isRepeat else { return .passThrough }

        capturedKeys.insert(keyCode)
        return .switchWindow(keyCode == 0x66 ? .previous : .next)
    }

    public mutating func reset() {
        capturedKeys.removeAll()
    }
}
