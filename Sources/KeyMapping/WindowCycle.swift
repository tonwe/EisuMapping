public enum WindowCycle {
    public static func destination(count: Int, current: Int?, direction: KeyMapping.Direction) -> Int? {
        guard count > 1 else { return nil }
        guard let current, (0..<count).contains(current) else {
            return direction == .next ? 0 : count - 1
        }
        return (current + (direction == .next ? 1 : count - 1)) % count
    }
}
