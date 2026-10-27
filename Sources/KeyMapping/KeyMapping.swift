/// JIS Eisu/Kana switch windows, or applications when Shift is held.
/// Captured releases are swallowed even if modifiers or enabled state change.
public struct KeyMapping {
    public struct Modifiers: OptionSet, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) { self.rawValue = rawValue }

        public static let shift = Self(rawValue: 1 << 0)
        public static let command = Self(rawValue: 1 << 1)
        public static let control = Self(rawValue: 1 << 2)
        public static let option = Self(rawValue: 1 << 3)
        public static let function = Self(rawValue: 1 << 4)
    }

    public enum Direction: Equatable, Sendable {
        case previous
        case next
    }

    public enum Action: Equatable, Sendable {
        case passThrough
        case suppress
        case switchWindow(Direction)
        case switchApplication(Direction)
    }

    public var isEnabled = true
    private var capturedKeys: Set<UInt16> = []

    public init() {}

    public mutating func handle(
        keyCode: UInt16, isKeyDown: Bool, isRepeat: Bool, modifiers: Modifiers
    ) -> Action {
        guard keyCode == 0x66 || keyCode == 0x68 else { return .passThrough }

        if !isKeyDown {
            return capturedKeys.remove(keyCode) != nil ? .suppress : .passThrough
        }
        if capturedKeys.contains(keyCode) { return .suppress }
        guard isEnabled, modifiers.subtracting(.shift).isEmpty, !isRepeat else { return .passThrough }

        capturedKeys.insert(keyCode)
        let direction: Direction = keyCode == 0x66 ? .previous : .next
        return modifiers.contains(.shift) ? .switchApplication(direction) : .switchWindow(direction)
    }

    public mutating func reset() {
        capturedKeys.removeAll()
    }
}
