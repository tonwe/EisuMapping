import Testing

@testable import KeyMapping

@Test func windowCycleWrapsInBothDirections() {
    #expect(SwitchCycle.destination(count: 3, current: 0, direction: .previous) == 2)
    #expect(SwitchCycle.destination(count: 3, current: 2, direction: .next) == 0)
    #expect(SwitchCycle.destination(count: 3, current: 1, direction: .previous) == 0)
    #expect(SwitchCycle.destination(count: 3, current: 1, direction: .next) == 2)
}

@Test func zeroOrOneWindowDoesNothing() {
    for count in [0, 1] {
        for direction: KeyMapping.Direction in [.previous, .next] {
            #expect(SwitchCycle.destination(count: count, current: 0, direction: direction) == nil)
        }
    }
}

@Test func missingFocusedWindowStartsAtEitherEnd() {
    #expect(SwitchCycle.destination(count: 3, current: nil, direction: .next) == 0)
    #expect(SwitchCycle.destination(count: 3, current: nil, direction: .previous) == 2)
    #expect(SwitchCycle.destination(count: 3, current: 3, direction: .next) == 0)
}

@Test func repeatedPressesVisitEveryWindowAndReverseBack() {
    var current = 0
    var visited: [Int] = []
    for _ in 0..<3 {
        current = SwitchCycle.destination(count: 3, current: current, direction: .next)!
        visited.append(current)
    }
    #expect(visited == [1, 2, 0])
    #expect(SwitchCycle.destination(count: 3, current: 1, direction: .previous) == 0)
}
